<#
.SYNOPSIS
  Behavioural tests for hooks/style-reminder.ps1 -- the Windows counterpart to
  tests/test-hook.sh, covering the same matrix.

.DESCRIPTION
  This hook runs on EVERY user prompt. Two failure modes matter more than the
  happy path:
    1. it must never block a turn (always exit 0), and
    2. it must never name the WRONG style -- reinforcing the global style
       inside a project that overrode it is worse than staying silent.

.EXAMPLE
  pwsh -NoProfile -File tests/Test-Hook.ps1     # from the repo root
#>
#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$hook = Join-Path $PSScriptRoot '..\hooks\style-reminder.ps1'
if (-not (Test-Path -LiteralPath $hook)) { Write-Error "not found: $hook"; exit 1 }
$hook = (Resolve-Path $hook).Path

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("stylehook-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
$proj = Join-Path $tmp 'proj'
$homeDir = Join-Path $tmp 'home\.claude'
New-Item -ItemType Directory -Force (Join-Path $proj '.claude') | Out-Null
New-Item -ItemType Directory -Force $homeDir | Out-Null

$projSettings = Join-Path $proj '.claude\settings.json'
$projLocal = Join-Path $proj '.claude\settings.local.json'
$userSettings = Join-Path $homeDir 'settings.json'

$script:pass = 0
$script:fail = 0

function Invoke-Hook {
    param([string] $Stdin)
    $env:CLAUDE_DIR = $homeDir
    # -File is safe here: an absolute path, so the ~-expansion caveat that
    # applies to the registered hook command does not bite.
    $out = $Stdin | & powershell.exe -NoProfile -File $hook 2>&1
    ($out | Out-String).Trim()
}

function Get-Payload { "{`"cwd`":`"$($proj -replace '\\','\\')`",`"hook_event_name`":`"UserPromptSubmit`"}" }

function Test-Case {
    param([string] $Label, [string] $Expected, [string] $Actual)
    if ($Expected -eq $Actual) {
        $script:pass++; "  ok    $Label"
    }
    else {
        $script:fail++
        "  FAIL  $Label"
        "         expected: [$Expected]"
        "         actual:   [$Actual]"
    }
}

function Get-Reminder { param([string] $N) "$N output style is active. Remember to follow the specific guidelines for this style." }

function Reset-Project {
    foreach ($f in @($projSettings, $projLocal)) { if (Test-Path -LiteralPath $f) { [IO.File]::Delete($f) } }
}

function Set-Json { param([string] $Path, [string] $Text) [IO.File]::WriteAllText($Path, $Text) }

'style-reminder.ps1'

# --- precedence -------------------------------------------------------------
Set-Json $userSettings '{"outputStyle":"No Slop"}'
Reset-Project
Test-Case 'user settings when project has none' (Get-Reminder 'No Slop') (Invoke-Hook (Get-Payload))

Set-Json $projSettings '{"outputStyle":"Caveman"}'
Test-Case 'project settings.json overrides user' (Get-Reminder 'Caveman') (Invoke-Hook (Get-Payload))

Set-Json $projLocal '{"outputStyle":"Executive"}'
Test-Case 'settings.local.json wins over both' (Get-Reminder 'Executive') (Invoke-Hook (Get-Payload))

Set-Json $projLocal '{"permissions":{}}'
Test-Case 'file without outputStyle falls through' (Get-Reminder 'Caveman') (Invoke-Hook (Get-Payload))

# --- must not break a turn --------------------------------------------------
Set-Json $projLocal '{BROKEN,,'
Test-Case 'malformed JSON falls through, no crash' (Get-Reminder 'Caveman') (Invoke-Hook (Get-Payload))

Reset-Project
Test-Case 'garbage stdin still resolves user scope' (Get-Reminder 'No Slop') (Invoke-Hook 'not json at all')
Test-Case 'empty stdin still resolves user scope' (Get-Reminder 'No Slop') (Invoke-Hook '')
Test-Case 'stdin JSON without cwd key' (Get-Reminder 'No Slop') (Invoke-Hook '{"prompt":"hi"}')
Test-Case 'stdin JSON with cwd null' (Get-Reminder 'No Slop') (Invoke-Hook '{"cwd":null}')

# --- silence where Claude Code already reminds ------------------------------
foreach ($b in 'default', 'Default', 'Explanatory', 'Learning', 'Proactive') {
    Set-Json $projSettings "{`"outputStyle`":`"$b`"}"
    Test-Case "silent for built-in '$b'" '' (Invoke-Hook (Get-Payload))
}

Reset-Project
Set-Json $userSettings ''
Test-Case 'silent when settings.json is empty' '' (Invoke-Hook (Get-Payload))

[IO.File]::Delete($userSettings)
Test-Case 'silent when no settings.json exists' '' (Invoke-Hook (Get-Payload))

# --- exit code is always 0 --------------------------------------------------
Set-Json $userSettings '{"outputStyle":"No Slop"}'
Get-Payload | & powershell.exe -NoProfile -File $hook > $null 2>&1
Test-Case 'exit 0 on the happy path' '0' "$LASTEXITCODE"

'garbage' | & powershell.exe -NoProfile -File $hook > $null 2>&1
Test-Case 'exit 0 on garbage stdin' '0' "$LASTEXITCODE"

[IO.File]::Delete($userSettings)
Get-Payload | & powershell.exe -NoProfile -File $hook > $null 2>&1
Test-Case 'exit 0 with no settings at all' '0' "$LASTEXITCODE"

$env:CLAUDE_DIR = $null
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

''
"$script:pass passed, $script:fail failed"
if ($script:fail -gt 0) { exit 1 }
