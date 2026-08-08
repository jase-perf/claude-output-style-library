# style-reminder.ps1 - a UserPromptSubmit hook that keeps custom output styles enforced.
#
# Windows counterpart to style-reminder.sh. Same job, same output.
#
# Claude Code injects a per-turn reminder ("<Name> output style is active.
# Remember to follow the specific guidelines for this style.") ONLY for its
# built-in styles. Custom styles are placed in the system prompt once and never
# reinforced, so their voice fades in long sessions. This hook emits the exact
# same reminder line for whatever custom style is active, closing that gap.
#
# It resolves outputStyle through Claude Code's settings precedence rather than
# reading only the user-level file. /config writes the output style to the
# PROJECT's .claude/settings.local.json, so a hook that reads just
# ~/.claude/settings.json would reinforce the global style inside a project
# that had overridden it -- worse than no reminder at all.
#
# Install: install.ps1 -Enforce   (or copy this file to ~/.claude/hooks/ and
# register it under hooks.UserPromptSubmit in ~/.claude/settings.json as:
#   powershell.exe -NoProfile ~/.claude/hooks/style-reminder.ps1
# Note: no -File. PowerShell does not expand ~ for the -File parameter.)
#
# Contract: this runs on EVERY prompt. It must never fail loudly and never
# block a turn -- every path exits 0.

try {
    # Claude Code pipes hook context as JSON on stdin; `cwd` is the project dir.
    # Guard on IsInputRedirected so a manual interactive run cannot block.
    $cwd = $null
    if ([Console]::IsInputRedirected) {
        $raw = [Console]::In.ReadToEnd()
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            # Unparseable stdin must degrade to the cwd fallback below, not
            # silence the hook entirely -- hence its own catch.
            try { $cwd = ($raw | ConvertFrom-Json).cwd } catch { $cwd = $null }
        }
    }
    if ([string]::IsNullOrWhiteSpace($cwd)) { $cwd = (Get-Location).Path }

    $userDir = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { Join-Path $env:USERPROFILE '.claude' }

    # Highest precedence first: local beats project beats user.
    # Nested Join-Path, not '.claude\settings.json': a backslash is an ordinary
    # filename character on macOS/Linux, so the one-string form would look for a
    # single file literally named ".claude\settings.json" under pwsh there.
    $projectClaude = Join-Path $cwd '.claude'
    $candidates = @(
        (Join-Path $projectClaude 'settings.local.json'),
        (Join-Path $projectClaude 'settings.json'),
        (Join-Path $userDir 'settings.json')
    )

    $style = $null
    foreach ($path in $candidates) {
        if (-not (Test-Path -LiteralPath $path)) { continue }
        try {
            $val = (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).outputStyle
        }
        catch { continue }   # a malformed file must not mask a valid one below it
        if (-not [string]::IsNullOrWhiteSpace($val)) { $style = $val; break }
    }

    if ([string]::IsNullOrWhiteSpace($style)) { exit 0 }

    # Built-ins already get this reminder from Claude Code itself.
    if ($style -in @('default', 'Default', 'Proactive', 'Explanatory', 'Learning')) { exit 0 }

    Write-Output "$style output style is active. Remember to follow the specific guidelines for this style."
}
catch {
    # A malformed or half-written settings file must not break the session.
    exit 0
}

exit 0
