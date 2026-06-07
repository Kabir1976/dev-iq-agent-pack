#Requires -Version 5.1
<#
.SYNOPSIS
  Dev.IQ Agent Pack — Bootstrap Installer (Windows / PowerShell)
.DESCRIPTION
  Installs the Dev.IQ Agent Pack into a target git repository.
  Mirrors bootstrap.sh exactly — same steps, same modes, same output.
.PARAMETER Target
  Target repository root. Defaults to current directory.
.PARAMETER Mode
  Install mode: 'trial' (local only, .git/info/exclude) or 'committed' (visible to git).
.PARAMETER Preset
  pod = committed mode + hooks (team install)
  solo = trial mode (individual developer)
  portable = committed mode, no hooks (client handoff)
.PARAMETER Graduate
  Convert a trial install to committed mode.
.PARAMETER Uninstall
  Remove Dev.IQ from the target repository.
.PARAMETER Hooks
  Also install the hooks/ directory.
.EXAMPLE
  .\scripts\bootstrap.ps1
.EXAMPLE
  .\scripts\bootstrap.ps1 -Target C:\Projects\my-repo -Preset solo
.EXAMPLE
  .\scripts\bootstrap.ps1 -Target C:\Projects\my-repo -Preset pod
.EXAMPLE
  .\scripts\bootstrap.ps1 -Target C:\Projects\my-repo -Graduate
.EXAMPLE
  .\scripts\bootstrap.ps1 -Target C:\Projects\my-repo -Uninstall
#>
param(
    [string]$Target  = (Get-Location).Path,
    [ValidateSet("trial","committed","")]
    [string]$Mode    = "",
    [ValidateSet("pod","solo","portable","")]
    [string]$Preset  = "",
    [switch]$Graduate,
    [switch]$Uninstall,
    [switch]$Hooks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PackVersion  = "0.9.0"
$PackRoot     = (Resolve-Path "$PSScriptRoot\..").Path
$MarkerStart  = "<!-- dev-iq:start -->"
$MarkerEnd    = "<!-- dev-iq:end -->"

# ── Console helpers ───────────────────────────────────────────────
function Write-Log   { param($Msg) Write-Host "[dev-iq] $Msg" -ForegroundColor White }
function Write-Ok    { param($Msg) Write-Host "[dev-iq] + $Msg" -ForegroundColor Green }
function Write-Warn  { param($Msg) Write-Host "[dev-iq] ! $Msg" -ForegroundColor Yellow }
function Write-Fail  { param($Msg) Write-Host "[dev-iq] x $Msg" -ForegroundColor Red; exit 1 }

# ── Validate prerequisites ────────────────────────────────────────
$PythonExe = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" }
             elseif (Get-Command python -ErrorAction SilentlyContinue) { "python" }
             else { Write-Fail "Python 3 is required but not found. Install from https://python.org"; "" }

if (-not (Test-Path $Target -PathType Container)) { Write-Fail "Target directory not found: $Target" }
if (-not (Test-Path "$Target\.git" -PathType Container)) { Write-Fail "Target is not a git repository: $Target" }
$Target = (Resolve-Path $Target).Path

# ── Apply preset ─────────────────────────────────────────────────
if ($Preset -ne "") {
    switch ($Preset) {
        "pod"      { $Mode = "committed"; $Hooks = $true }
        "solo"     { $Mode = "trial";     $Hooks = $false }
        "portable" { $Mode = "committed"; $Hooks = $false }
    }
}

# ── Detect existing install ───────────────────────────────────────
$ManifestPath = "$Target\.dev-iq\.install-manifest.json"
$IsUpgrade    = $false

if (Test-Path $ManifestPath) {
    $IsUpgrade   = $true
    $ManifestObj = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    $PrevVersion = $ManifestObj.version
    $PrevMode    = $ManifestObj.mode
    Write-Host ""
    Write-Log "Existing Dev.IQ install detected."
    Write-Log "  Installed version : v$PrevVersion"
    Write-Log "  New pack version  : v$PackVersion"
    Write-Log "  Current mode      : $PrevMode"
    Write-Host ""
}

# ── Uninstall mode ───────────────────────────────────────────────
if ($Uninstall) {
    Write-Host ""
    Write-Log "Removing Dev.IQ Agent Pack from: $Target"
    Write-Host ""

    $Confirm = Read-Host "  This will delete Dev.IQ files from $Target. Continue? [y/N]"
    if ($Confirm -ne "y") { Write-Log "Uninstall cancelled."; exit 0 }

    # Remove pack-owned directories
    foreach ($Dir in @(".github\skills", ".github\instructions", ".github\agents", ".claude\agents")) {
        $FullDir = "$Target\$Dir"
        if (Test-Path $FullDir) {
            Remove-Item -Recurse -Force $FullDir
            Write-Ok "Removed : $Dir"
        }
    }

    # Remove pack-owned files
    $SkillsMd = "$Target\.claude\skills.md"
    if (Test-Path $SkillsMd) { Remove-Item -Force $SkillsMd; Write-Ok "Removed : .claude\skills.md" }

    # Remove dev-iq marker block from CLAUDE.md
    $ClaudeDst = "$Target\CLAUDE.md"
    if ((Test-Path $ClaudeDst) -and ((Get-Content $ClaudeDst -Raw) -match [regex]::Escape($MarkerStart))) {
        $PyScript = @"
import sys, re
dst, ms, me = sys.argv[1], sys.argv[2], sys.argv[3]
with open(dst, encoding='utf-8') as f: content = f.read()
pattern = re.escape(ms) + r'.*?' + re.escape(me)
result = re.sub(pattern, '', content, flags=re.DOTALL).strip()
with open(dst, 'w', encoding='utf-8') as f: f.write(result + '\n' if result else '')
"@
        $TmpPy = [System.IO.Path]::GetTempFileName() + ".py"
        $PyScript | Set-Content $TmpPy -Encoding UTF8
        & $PythonExe $TmpPy $ClaudeDst $MarkerStart $MarkerEnd
        Remove-Item $TmpPy -ErrorAction SilentlyContinue
        Write-Ok "Removed Dev.IQ block from CLAUDE.md."
        if (-not (Get-Content $ClaudeDst -Raw).Trim()) {
            Remove-Item -Force $ClaudeDst; Write-Ok "Removed empty CLAUDE.md."
        }
    }

    # Remove trial entries from .git\info\exclude
    $ExcludePath = "$Target\.git\info\exclude"
    if ((Test-Path $ExcludePath) -and ((Get-Content $ExcludePath -Raw) -match "# dev-iq")) {
        $Lines = Get-Content $ExcludePath |
            Where-Object { $_ -notmatch "^# dev-iq" } |
            Where-Object { $_ -notmatch "^\.github/skills" } |
            Where-Object { $_ -notmatch "^\.github/instructions" } |
            Where-Object { $_ -notmatch "^\.github/agents" } |
            Where-Object { $_ -notmatch "^\.claude/agents" } |
            Where-Object { $_ -notmatch "^\.claude/skills" } |
            Where-Object { $_ -notmatch "^\.dev-iq" } |
            Where-Object { $_ -notmatch "^hooks/" } |
            Where-Object { $_ -notmatch "^CLAUDE\.md" }
        $Lines | Set-Content $ExcludePath -Encoding UTF8
        Write-Ok "Removed trial entries from .git\info\exclude."
    }

    # Remove .dev-iq/ directory
    if (Test-Path "$Target\.dev-iq") {
        Remove-Item -Recurse -Force "$Target\.dev-iq"
        Write-Ok "Removed : .dev-iq\"
    }

    Write-Host ""
    Write-Ok "Dev.IQ removed from $Target."
    Write-Host ""
    Write-Log "User-created files (your code, tests, configs) were not touched."
    exit 0
}

# ── Graduate mode ─────────────────────────────────────────────────
if ($Graduate) {
    if (-not $IsUpgrade) { Write-Fail "No existing install found. Run bootstrap first, then -Graduate." }

    $ExcludePath = "$Target\.git\info\exclude"
    if (Test-Path $ExcludePath) {
        $Lines = Get-Content $ExcludePath |
            Where-Object { $_ -notmatch "^# dev-iq" } |
            Where-Object { $_ -notmatch "^\.github/skills" } |
            Where-Object { $_ -notmatch "^\.github/instructions" } |
            Where-Object { $_ -notmatch "^\.github/agents" } |
            Where-Object { $_ -notmatch "^\.claude/agents" } |
            Where-Object { $_ -notmatch "^\.claude/skills" } |
            Where-Object { $_ -notmatch "^\.dev-iq" } |
            Where-Object { $_ -notmatch "^hooks/" } |
            Where-Object { $_ -notmatch "^CLAUDE\.md" }
        $Lines | Set-Content $ExcludePath -Encoding UTF8
        Write-Ok "Removed trial entries from .git\info\exclude."
    }

    $ManifestObj = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    $ManifestObj.mode = "committed"
    $ManifestObj | Add-Member -MemberType NoteProperty -Name graduated_at `
        -Value ([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) -Force
    $ManifestObj | ConvertTo-Json -Depth 5 | Set-Content $ManifestPath -Encoding UTF8

    Write-Ok "Graduated to committed mode."
    Write-Host ""
    Write-Log "Dev.IQ files are now visible to git."
    Write-Log "Next: review the files, then git add and open a team PR."
    exit 0
}

# ── Select install mode ───────────────────────────────────────────
if ($Mode -eq "") {
    Write-Host ""
    Write-Log "Select install mode:"
    Write-Host ""
    Write-Host "  [1] trial     — local only, completely invisible to git"
    Write-Host "            Files go in .git\info\exclude — the codebase is not modified."
    Write-Host "            Graduate to committed later when the team is ready."
    Write-Host ""
    Write-Host "  [2] committed — files visible to git"
    Write-Host "            Team can review, commit, and share the pack as a normal PR."
    Write-Host ""
    $Choice = Read-Host "  Choice [1/2] (default: 1)"
    $Mode   = if ($Choice -eq "2") { "committed" } else { "trial" }
}

Write-Host ""
Write-Log "─────────────────────────────────────────────"
Write-Log "  Dev.IQ Agent Pack v$PackVersion"
Write-Log "  Target : $Target"
Write-Log "  Mode   : $Mode$(if ($Preset) { " (preset: $Preset)" } else { '' })"
Write-Log "─────────────────────────────────────────────"
Write-Host ""

# ── File copy helpers ─────────────────────────────────────────────
function Copy-PackFile {
    param([string]$Src, [string]$Dst, [bool]$Preserve = $false)
    $DstDir = Split-Path $Dst -Parent
    if (-not (Test-Path $DstDir)) { New-Item -ItemType Directory -Path $DstDir -Force | Out-Null }
    if ($Preserve -and (Test-Path $Dst)) {
        Write-Warn "Preserved existing : $($Dst.Replace($Target + '\', ''))"
        return
    }
    Copy-Item -Path $Src -Destination $Dst -Force
    Write-Ok "Installed : $($Dst.Replace($Target + '\', ''))"
}

function Copy-PackDir {
    param([string]$Src, [string]$Dst)
    Get-ChildItem -Path $Src -Recurse -File | ForEach-Object {
        $Rel = $_.FullName.Substring($Src.Length + 1)
        Copy-PackFile -Src $_.FullName -Dst "$Dst\$Rel" -Preserve $false
    }
}

# ── Install pack-owned files ──────────────────────────────────────
Copy-PackDir "$PackRoot\.github\skills"       "$Target\.github\skills"
Copy-PackDir "$PackRoot\.github\instructions" "$Target\.github\instructions"
Copy-PackDir "$PackRoot\.github\agents"       "$Target\.github\agents"
Copy-PackDir "$PackRoot\.claude\agents"       "$Target\.claude\agents"
Copy-PackFile "$PackRoot\.claude\skills.md"   "$Target\.claude\skills.md"

# ── Install user-configured stubs ─────────────────────────────────
Copy-PackFile "$PackRoot\.dev-iq\config.yaml"          "$Target\.dev-iq\config.yaml"          $true
Copy-PackFile "$PackRoot\.dev-iq\governance.md"         "$Target\.dev-iq\governance.md"         $true
Copy-PackFile "$PackRoot\.dev-iq\maturity-profile.md"   "$Target\.dev-iq\maturity-profile.md"   $true
Copy-PackFile "$PackRoot\.dev-iq\telemetry-overlay.md"  "$Target\.dev-iq\telemetry-overlay.md"  $true

# ── Install hooks (optional) ──────────────────────────────────────
if ($Hooks) {
    Copy-PackDir "$PackRoot\hooks" "$Target\hooks"
    Write-Ok "Hooks installed."
}

# ── CLAUDE.md injection ───────────────────────────────────────────
$ClaudeSrc     = "$PackRoot\CLAUDE.md"
$ClaudeDst     = "$Target\CLAUDE.md"
$ClaudeContent = Get-Content $ClaudeSrc -Raw -Encoding UTF8

if (-not (Test-Path $ClaudeDst)) {
    "$MarkerStart`n$ClaudeContent`n$MarkerEnd" | Set-Content $ClaudeDst -Encoding UTF8
    Write-Ok "Created CLAUDE.md with Dev.IQ instructions."
} elseif ((Get-Content $ClaudeDst -Raw) -match [regex]::Escape($MarkerStart)) {
    $PyScript = @"
import sys
dst, src = sys.argv[1], sys.argv[2]
ms, me = '$MarkerStart', '$MarkerEnd'
with open(dst, encoding='utf-8') as f: orig = f.read()
with open(src, encoding='utf-8') as f: new  = f.read()
block = ms + '\n' + new + '\n' + me
si, ei = orig.find(ms), orig.find(me)
result = orig[:si] + block + orig[ei + len(me):]
with open(dst, 'w', encoding='utf-8') as f: f.write(result)
"@
    $TmpPy = [System.IO.Path]::GetTempFileName() + ".py"
    $PyScript | Set-Content $TmpPy -Encoding UTF8
    & $PythonExe $TmpPy $ClaudeDst $ClaudeSrc
    Remove-Item $TmpPy -ErrorAction SilentlyContinue
    Write-Ok "Updated Dev.IQ block in existing CLAUDE.md."
} else {
    $Existing = Get-Content $ClaudeDst -Raw -Encoding UTF8
    "$Existing`n`n$MarkerStart`n$ClaudeContent`n$MarkerEnd" | Set-Content $ClaudeDst -Encoding UTF8
    Write-Ok "Appended Dev.IQ instructions to existing CLAUDE.md."
}

# ── Trial mode: add paths to .git\info\exclude ───────────────────
if ($Mode -eq "trial") {
    $ExcludePath = "$Target\.git\info\exclude"
    $ExcludeDir  = Split-Path $ExcludePath -Parent
    if (-not (Test-Path $ExcludeDir)) { New-Item -ItemType Directory -Path $ExcludeDir -Force | Out-Null }
    if (-not (Test-Path $ExcludePath)) { New-Item -ItemType File -Path $ExcludePath -Force | Out-Null }

    $ExcludeContent = Get-Content $ExcludePath -Raw -ErrorAction SilentlyContinue
    if ($ExcludeContent -match "# dev-iq") {
        Write-Warn "Trial mode entries already present in .git\info\exclude."
    } else {
        $Block = "`n# dev-iq — trial install v$PackVersion`n.github/skills/`n.github/instructions/`n.github/agents/`n.claude/agents/`n.claude/skills.md`n.dev-iq/`nCLAUDE.md"
        if ($Hooks) { $Block += "`nhooks/" }
        Add-Content $ExcludePath $Block -Encoding UTF8
        Write-Ok "Dev.IQ paths added to .git\info\exclude (invisible to git)."
    }
}

# ── Write install manifest ────────────────────────────────────────
$ManifestDir = "$Target\.dev-iq"
if (-not (Test-Path $ManifestDir)) { New-Item -ItemType Directory -Path $ManifestDir -Force | Out-Null }

$ManifestData = [ordered]@{
    version         = $PackVersion
    installed_at    = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    mode            = $Mode
    pack_source     = $PackRoot
    hooks_installed = $Hooks.IsPresent
    is_upgrade      = $IsUpgrade
}
$ManifestData | ConvertTo-Json -Depth 5 | Set-Content $ManifestPath -Encoding UTF8
Write-Ok "Manifest written : .dev-iq\.install-manifest.json"

# ── Summary ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Dev.IQ Agent Pack v$PackVersion installed successfully. ($Mode mode)" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Edit .dev-iq\config.yaml"
Write-Host "     Set: client name, maturity tier (early/mid/higher), tracker type (ado/jira)"
Write-Host "  2. Open VS Code in this project"
Write-Host "  3. In Copilot Chat or Claude Code, select the Dev-IQ agent"
Write-Host "  4. Type / to see all available skills"
Write-Host "  5. Run /explain-code on any file to verify the install"
Write-Host ""
if ($Mode -eq "trial") {
    Write-Host "  To share with your team when ready:"
    Write-Host "  .\path\to\dev-iq\scripts\bootstrap.ps1 -Target '$Target' -Graduate"
    Write-Host ""
}
