<#
.SYNOPSIS
  awesome-claude-output-styles installer for Windows (PowerShell 5.1+).

.DESCRIPTION
  The Windows counterpart to install.sh. Same interface, no dependencies:
  install.sh needs bash + python3, neither of which is reliably present on
  Windows -- and both fail in ways that look like success (see "Why not just
  run install.sh" in README.md).

  Everything here uses built-in PowerShell: no curl, no bash, no python.

.EXAMPLE
  # Install one style and make it active
  irm https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.ps1 | iex

.EXAMPLE
  # Pass arguments (irm | iex cannot take parameters, so wrap in a scriptblock)
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main/install.ps1))) -Style eli15 -Enforce

.EXAMPLE
  # From a local checkout
  .\install.ps1 -All -Enforce
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
    # One or more style names. A single style is also activated.
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $Style,

    # Install all styles + the style-maker skill. Activates nothing.
    [switch] $All,

    # Print available style names and exit.
    [switch] $List,

    # Also install the per-turn UserPromptSubmit reminder hook.
    [switch] $Enforce,

    [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # the progress bar makes downloads ~10x slower

$STYLES = @(
    'wait-what', 'plain-english', 'eli15', 'analogy-engine', 'feynman', 'thing-explainer', 'ladder',
    'executive', 'smart-brevity', 'coach',
    'caveman', 'adhd', 'no-slop', 'no-ai-slop',
    'street', 'gen-z', 'sportscaster', 'yoda', 'bedtime-story'
)

$ClaudeDir = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$IsDefaultClaudeDir = -not $env:CLAUDE_DIR
$Raw = if ($env:RAW) { $env:RAW } else { 'https://raw.githubusercontent.com/jase-perf/claude-output-style-library/main' }

# When run from a local checkout, install from local files instead of downloading.
# $PSScriptRoot is empty when the script is piped through iex, which is exactly
# when we want the remote path.
$SelfDir = $null
if ($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot "output-styles\$($STYLES[0]).md"))) {
    $SelfDir = $PSScriptRoot
}

function Show-Usage {
    @"
Usage:
  .\install.ps1 -Style <name> [<name>...] [-Enforce]
  .\install.ps1 -All [-Enforce]
  .\install.ps1 -List

Styles: $($STYLES -join ' ') style-maker
  -Enforce  install a per-turn reminder hook so the active style never fades
"@
}

function Write-TextFile {
    param([string] $Path, [string] $Text)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    # UTF8Encoding($false) = no BOM. Set-Content -Encoding UTF8 emits a BOM on
    # PS 5.1, which trips strict JSON parsers.
    [IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-Asset {
    param([string] $RelPath, [string] $Destination)
    if ($SelfDir) {
        $src = Join-Path $SelfDir ($RelPath -replace '/', '\')
        $dir = Split-Path -Parent $Destination
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }
        Copy-Item -LiteralPath $src -Destination $Destination -Force
    }
    else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $content = (Invoke-WebRequest -Uri "$Raw/$RelPath" -UseBasicParsing).Content
        if ($content -is [byte[]]) { $content = [Text.Encoding]::UTF8.GetString($content) }
        Write-TextFile -Path $Destination -Text $content
    }
}

# --- settings.json helpers -------------------------------------------------
# ConvertFrom-Json returns PSCustomObject, which is awkward to mutate and (on
# PS 5.1) has no -AsHashtable. Convert to ordered hashtables so merges are
# simple and key order round-trips unchanged.
function ConvertTo-OrderedHashtable {
    param($InputObject)
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IList]) {
        $list = @()
        foreach ($item in $InputObject) { $list += , (ConvertTo-OrderedHashtable $item) }
        return , $list
    }
    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $h = [ordered]@{}
        foreach ($p in $InputObject.PSObject.Properties) {
            $h[$p.Name] = ConvertTo-OrderedHashtable $p.Value
        }
        return $h
    }
    return $InputObject
}

function Update-Settings {
    param([scriptblock] $Mutate)
    $path = Join-Path $ClaudeDir 'settings.json'
    $data = [ordered]@{}
    if (Test-Path -LiteralPath $path) {
        Copy-Item -LiteralPath $path -Destination "$path.bak" -Force
        $raw = [IO.File]::ReadAllText($path)
        if ($raw.Trim()) {
            $parsed = ConvertTo-OrderedHashtable ($raw | ConvertFrom-Json)
            if ($parsed) { $data = $parsed }
        }
    }
    & $Mutate $data
    # -Depth 100 is not optional: PS 5.1 defaults to 2 and silently flattens
    # anything deeper (the hooks tree) into "System.Object[]" strings.
    Write-TextFile -Path $path -Text ($data | ConvertTo-Json -Depth 100)
    return $path
}

# --- install steps ---------------------------------------------------------
function Install-Style {
    param([string] $Name)
    Get-Asset "output-styles/$Name.md" (Join-Path $ClaudeDir "output-styles\$Name.md")
    Write-Host "installed: output-styles/$Name.md"
}

function Install-StyleMaker {
    Get-Asset 'skills/style-maker/SKILL.md' (Join-Path $ClaudeDir 'skills\style-maker\SKILL.md')
    Write-Host 'installed: skills/style-maker (ask Claude to "make my output style")'
}

function Install-EnforceHook {
    $hookPath = Join-Path $ClaudeDir 'hooks\style-reminder.ps1'
    Get-Asset 'hooks/style-reminder.ps1' $hookPath

    # Prefer the ~ form so a settings.json synced between machines stays valid.
    # No -File: PowerShell does not expand ~ for the -File parameter, so the
    # hook would fail on every turn.
    $target = if ($IsDefaultClaudeDir) { '~/.claude/hooks/style-reminder.ps1' } else { $hookPath }
    $cmd = "powershell.exe -NoProfile $target"

    $settings = Update-Settings {
        param($data)
        if (-not $data.Contains('hooks')) { $data['hooks'] = [ordered]@{} }
        if (-not $data['hooks'].Contains('UserPromptSubmit')) { $data['hooks']['UserPromptSubmit'] = @() }

        $groups = @($data['hooks']['UserPromptSubmit'])
        foreach ($group in $groups) {
            if ($group -and $group.Contains('hooks')) {
                foreach ($h in @($group['hooks'])) {
                    if ($h -and $h.Contains('command') -and $h['command'] -eq $cmd) { return }
                }
            }
        }
        $entry = [ordered]@{
            matcher = ''
            hooks   = @([ordered]@{ type = 'command'; command = $cmd; timeout = 5 })
        }
        $data['hooks']['UserPromptSubmit'] = @($groups + $entry)
    }
    Write-Host "installed: hooks/style-reminder.ps1 (per-turn reminder, registered in $settings)"
}

function Set-ActiveStyle {
    param([string] $Name)
    $file = Join-Path $ClaudeDir "output-styles\$Name.md"
    $styleName = $null
    foreach ($line in [IO.File]::ReadAllLines($file)) {
        if ($line -match '^name:\s*(.+?)\s*$') { $styleName = $Matches[1]; break }
    }
    if (-not $styleName) {
        Write-Host 'warning: no name in frontmatter, skipping activation'
        return
    }
    $settings = Update-Settings {
        param($data)
        $data['outputStyle'] = $styleName
    }
    Write-Host "active style: $styleName (written to $settings)"
    Write-Host 'Restart Claude Code (or /clear) to apply.'
}

# --- main ------------------------------------------------------------------
if ($Help) { Show-Usage; return }
if ($List) { $STYLES + 'style-maker' | ForEach-Object { Write-Host $_ }; return }

if ($All) {
    foreach ($s in $STYLES) { Install-Style $s }
    Install-StyleMaker
    if ($Enforce) { Install-EnforceHook }
    Write-Host ''
    Write-Host 'All styles installed. Pick one: /config -> Output style (takes effect after restart or /clear).'
    return
}

if (-not $Style -or $Style.Count -eq 0) { Show-Usage; exit 1 }

foreach ($s in $Style) {
    if ($s -eq 'style-maker') { Install-StyleMaker; continue }
    if ($STYLES -notcontains $s) {
        Write-Host "unknown style: $s"
        Show-Usage
        exit 1
    }
    Install-Style $s
}

if ($Enforce) { Install-EnforceHook }

# Exactly one style requested -> make it the active style.
$requested = @($Style | Where-Object { $_ -ne 'style-maker' })
if ($requested.Count -eq 1) {
    Set-ActiveStyle $requested[0]
}
else {
    Write-Host ''
    Write-Host 'Pick a style: /config -> Output style (takes effect after restart or /clear).'
}
