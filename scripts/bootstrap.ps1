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
.PARAMETER DryRun
  Preview what would be installed without writing any files.
.PARAMETER Yes
  Skip interactive confirmation prompts (default to trial mode).
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
    [switch]$Hooks,
    [switch]$DryRun,
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PackVersion  = "0.11.0"
$PackRoot     = (Resolve-Path "$PSScriptRoot\..").Path
$MarkerStart  = "<!-- dev-iq:begin v=$PackVersion -->"
$MarkerEnd    = "<!-- dev-iq:end -->"
# CONFLICT_BULK_CHOICE: K = keep all existing files, O = overwrite all files.
$ConflictBulkChoice = $env:CONFLICT_BULK_CHOICE

# ── Console helpers ───────────────────────────────────────────────
function Write-Log   { param($Msg) Write-Host "[dev-iq] $Msg" -ForegroundColor White }
function Write-Ok    { param($Msg) Write-Host "[dev-iq] + $Msg" -ForegroundColor Green }
function Write-Warn  { param($Msg) Write-Host "[dev-iq] ! $Msg" -ForegroundColor Yellow }
function Write-Fail  { param($Msg) Write-Host "[dev-iq] x $Msg" -ForegroundColor Red; exit 1 }

# ── Validate prerequisites ────────────────────────────────────────
if (-not (Test-Path $Target -PathType Container)) { Write-Fail "Target directory not found: $Target" }
if (-not (Test-Path "$Target\.git" -PathType Container)) { Write-Fail "Target is not a git repository: $Target" }
$Target = (Resolve-Path $Target).Path

# ── Auto-detect project context ───────────────────────────────────
$DetectedTracker   = "ado"
$DetectedVcs       = "github"
$DetectedAdoOrg    = ""
$DetectedAdoProject = ""
$DetectedLang      = ""
$DetectedFramework = ""

function Invoke-ContextDetection {
    # Tracker + VCS from git remote URL
    try {
        $RemoteUrl = git -C $Target remote get-url origin 2>$null
    } catch { $RemoteUrl = "" }

    if ($RemoteUrl -match "dev\.azure\.com") {
        $script:DetectedTracker = "ado"
        $script:DetectedVcs     = "ado-repos"
        if ($RemoteUrl -match "dev\.azure\.com/([^/@]+)/([^/]+)") {
            $script:DetectedAdoOrg     = "https://dev.azure.com/$($Matches[1])"
            $script:DetectedAdoProject = $Matches[2]
        }
    } elseif ($RemoteUrl -match "github\.com") {
        $script:DetectedVcs     = "github"
        $script:DetectedTracker = "github-issues"
    } elseif ($RemoteUrl -match "gitlab\.com") {
        $script:DetectedVcs = "gitlab"
    } elseif ($RemoteUrl -match "bitbucket\.org") {
        $script:DetectedVcs = "bitbucket"
    }

    # Language from project files
    if (Test-Path "$Target\package.json") {
        $script:DetectedLang = if (Test-Path "$Target\tsconfig.json") { "typescript" } else { "javascript" }
    } elseif ((Test-Path "$Target\requirements.txt") -or (Test-Path "$Target\pyproject.toml") -or (Test-Path "$Target\setup.py")) {
        $script:DetectedLang = "python"
    } elseif (Test-Path "$Target\pom.xml") {
        $script:DetectedLang = "java"
    } elseif (Get-ChildItem "$Target\*.csproj" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) {
        $script:DetectedLang = "csharp"
    } elseif (Get-ChildItem "$Target\build.gradle*" -ErrorAction SilentlyContinue | Select-Object -First 1) {
        $script:DetectedLang = "java"
    } elseif (Test-Path "$Target\go.mod") {
        $script:DetectedLang = "go"
    } elseif (Test-Path "$Target\Gemfile") {
        $script:DetectedLang = "ruby"
    } elseif (Test-Path "$Target\Cargo.toml") {
        $script:DetectedLang = "rust"
    }

    # Framework from package.json
    if (Test-Path "$Target\package.json") {
        $Pkg = Get-Content "$Target\package.json" -Raw -ErrorAction SilentlyContinue
        if     ($Pkg -match '"next"')           { $script:DetectedFramework = "nextjs" }
        elseif ($Pkg -match '"react"')          { $script:DetectedFramework = "react" }
        elseif ($Pkg -match '"@angular/core"')  { $script:DetectedFramework = "angular" }
        elseif ($Pkg -match '"vue"')            { $script:DetectedFramework = "vue" }
        elseif ($Pkg -match '"@nestjs/core"')   { $script:DetectedFramework = "nestjs" }
        elseif ($Pkg -match '"express"')        { $script:DetectedFramework = "express" }
    } elseif (Test-Path "$Target\requirements.txt") {
        $Reqs = Get-Content "$Target\requirements.txt" -Raw -ErrorAction SilentlyContinue
        if     ($Reqs -imatch "fastapi") { $script:DetectedFramework = "fastapi" }
        elseif ($Reqs -imatch "django")  { $script:DetectedFramework = "django" }
        elseif ($Reqs -imatch "flask")   { $script:DetectedFramework = "flask" }
    }
}

Invoke-ContextDetection

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

    if (-not $Yes) {
        $Confirm = Read-Host "  This will delete Dev.IQ files from $Target. Continue? [y/N]"
        if ($Confirm -ne "y") { Write-Log "Uninstall cancelled."; exit 0 }
    }

    $Restored = 0
    $Deleted  = 0

    # Restore or delete pack-owned files inside pack-owned directories.
    foreach ($Dir in @(".github\skills", ".github\instructions", ".github\agents", ".claude\agents")) {
        $FullDir = "$Target\$Dir"
        if (Test-Path $FullDir) {
            Get-ChildItem -Path $FullDir -Recurse -File |
                Where-Object { $_.Name -notmatch '\.di\.pre-install$' } |
                ForEach-Object {
                    $PreInstall = "$($_.FullName).di.pre-install"
                    if (Test-Path $PreInstall) {
                        Move-Item -Path $PreInstall -Destination $_.FullName -Force
                        $script:Restored++
                    } else {
                        Remove-Item -Force $_.FullName
                        $script:Deleted++
                    }
                }
            # Remove now-empty subdirectories.
            Get-ChildItem -Path $FullDir -Recurse -Directory |
                Sort-Object FullName -Descending |
                Where-Object { (Get-ChildItem $_.FullName -Force | Measure-Object).Count -eq 0 } |
                ForEach-Object { Remove-Item -Force $_.FullName }
            if (Test-Path $FullDir) {
                if ((Get-ChildItem $FullDir -Force | Measure-Object).Count -eq 0) {
                    Remove-Item -Force $FullDir
                }
            }
            Write-Ok "Processed : $Dir"
        }
    }

    # Restore or delete individual pack-owned files.
    $SkillsMd = "$Target\.claude\skills.md"
    if (Test-Path $SkillsMd) {
        $PreInstall = "$SkillsMd.di.pre-install"
        if (Test-Path $PreInstall) {
            Move-Item -Path $PreInstall -Destination $SkillsMd -Force
            $Restored++
        } else {
            Remove-Item -Force $SkillsMd
            $Deleted++
        }
        Write-Ok "Processed : .claude\skills.md"
    }

    # Helper: remove dev-iq marker block from a Markdown file (handles begin/start formats).
    function Remove-DiMarkerBlock {
        param([string]$FilePath, [string]$Label)
        if (-not (Test-Path $FilePath)) { return }
        $Raw = Get-Content $FilePath -Raw -Encoding UTF8
        if ($Raw -notmatch '<!-- dev-iq:(begin|start)') { return }
        $Pattern = '<!-- dev-iq:[\s\S]*?<!-- dev-iq:end -->'
        $Cleaned = [regex]::Replace($Raw, $Pattern, '').Trim()
        $Cleaned | Set-Content $FilePath -Encoding UTF8
        Write-Ok "Removed Dev.IQ block from $Label."
        if (-not (Get-Content $FilePath -Raw -ErrorAction SilentlyContinue).Trim()) {
            Remove-Item -Force $FilePath; Write-Ok "Removed empty $Label."
        }
    }

    Remove-DiMarkerBlock "$Target\CLAUDE.md"  "CLAUDE.md"
    Remove-DiMarkerBlock "$Target\AGENTS.md"  "AGENTS.md"
    Remove-DiMarkerBlock "$Target\.github\copilot-instructions.md"  "copilot-instructions.md"

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
            Where-Object { $_ -notmatch "^CLAUDE\.md" } |
            Where-Object { $_ -notmatch "^AGENTS\.md" } |
            Where-Object { $_ -notmatch "^\.github/copilot-instructions" }
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
    Write-Log "Restored $Restored pre-install files, deleted $Deleted."
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
            Where-Object { $_ -notmatch "^CLAUDE\.md" } |
            Where-Object { $_ -notmatch "^AGENTS\.md" } |
            Where-Object { $_ -notmatch "^\.github/copilot-instructions" }
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
    if ($Yes) {
        $Mode = "trial"
    } else {
        Write-Host ""
        $Choice = Read-Host "  Just you, or the whole team?  [1] Just me  [2] Whole team  (default: 1)"
        $Mode   = if ($Choice -eq "2") { "committed" } else { "trial" }
    }
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
    if ($DryRun) {
        Write-Host "  [dry-run] would copy: $Src -> $($Dst.Replace($Target + '\', ''))"
        return
    }
    $DstDir = Split-Path $Dst -Parent
    if (-not (Test-Path $DstDir)) { New-Item -ItemType Directory -Path $DstDir -Force | Out-Null }
    # CONFLICT_BULK_CHOICE=K forces keep; =O forces overwrite regardless of Preserve flag.
    $EffectivePreserve = $Preserve
    if ($ConflictBulkChoice -eq "K" -and (Test-Path $Dst)) { $EffectivePreserve = $true }
    if ($ConflictBulkChoice -eq "O") { $EffectivePreserve = $false }
    if ($EffectivePreserve -and (Test-Path $Dst)) {
        Write-Warn "Preserved existing : $($Dst.Replace($Target + '\', ''))"
        return
    }
    # Save pre-install snapshot before overwriting an existing file.
    if (Test-Path $Dst) {
        Copy-Item -Path $Dst -Destination "$Dst.di.pre-install" -Force
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

# ── Config pre-fill with auto-detected values ────────────────────
function Invoke-PrefillConfig {
    param([string]$ConfigPath)
    if (-not (Test-Path $ConfigPath) -or $IsUpgrade) { return }

    $Content = Get-Content $ConfigPath -Raw -Encoding UTF8

    # tracker.type: config default is "ado"; overwrite with detected value.
    if ($DetectedTracker) {
        $Content = $Content -replace 'type: "ado"', "type: `"$DetectedTracker`""
        # signals.intent.source mirrors tracker
        $Content = $Content -replace 'source: "ado"', "source: `"$DetectedTracker`""
    }

    # vcs.type: config default is "github"; only overwrite when different.
    if ($DetectedVcs -and $DetectedVcs -ne "github") {
        $Content = $Content -replace 'type: "github"', "type: `"$DetectedVcs`""
    }

    # ado.org_url — empty string placeholder.
    if ($DetectedAdoOrg) {
        $Content = $Content -replace 'org_url: ""', "org_url: `"$DetectedAdoOrg`""
    }

    # ado.project — first empty project: "".
    if ($DetectedAdoProject) {
        $Content = [regex]::Replace($Content, 'project: ""', "project: `"$DetectedAdoProject`"", 1)
    }

    # stack.languages — first "    - """.
    if ($DetectedLang) {
        $Content = [regex]::Replace($Content, '    - ""', "    - `"$DetectedLang`"", 1)
    }

    # stack.frameworks — first remaining "    - """.
    if ($DetectedFramework) {
        $Content = [regex]::Replace($Content, '    - ""', "    - `"$DetectedFramework`"", 1)
    }

    $Content | Set-Content $ConfigPath -Encoding UTF8 -NoNewline
}

# ── Install pack-owned files ──────────────────────────────────────
Copy-PackDir "$PackRoot\.github\skills"       "$Target\.github\skills"
Copy-PackDir "$PackRoot\.github\instructions" "$Target\.github\instructions"
Copy-PackDir "$PackRoot\.github\agents"       "$Target\.github\agents"
Copy-PackDir "$PackRoot\.claude\agents"       "$Target\.claude\agents"
Copy-PackFile "$PackRoot\.claude\skills.md"   "$Target\.claude\skills.md"

# ── Install user-configured stubs ─────────────────────────────────
Copy-PackFile "$PackRoot\.dev-iq\config.yaml"          "$Target\.dev-iq\config.yaml"          $true
try { Invoke-PrefillConfig "$Target\.dev-iq\config.yaml" }
catch { Write-Warn "Config pre-fill skipped (unexpected error) — edit .dev-iq\config.yaml manually." }
Copy-PackFile "$PackRoot\.dev-iq\governance.md"         "$Target\.dev-iq\governance.md"         $true
Copy-PackFile "$PackRoot\.dev-iq\maturity-profile.md"   "$Target\.dev-iq\maturity-profile.md"   $true
Copy-PackFile "$PackRoot\.dev-iq\telemetry-overlay.md"  "$Target\.dev-iq\telemetry-overlay.md"  $true

# ── Install hooks (optional) ──────────────────────────────────────
if ($Hooks) {
    Copy-PackDir "$PackRoot\hooks" "$Target\hooks"
    Write-Ok "Hooks installed."
}

# ── Markdown file injection (idempotent merge-marker) ─────────────
# Wraps pack content in <!-- dev-iq:begin / dev-iq:end --> markers.
# Re-runs replace only the marker block, leaving user content outside
# the markers untouched. Handles both old (dev-iq:start) and new
# (dev-iq:begin v=X) marker formats for safe upgrades.

function Invoke-InjectMd {
    param([string]$Src, [string]$Dst, [string]$Label)
    $SrcContent = Get-Content $Src -Raw -Encoding UTF8
    if (-not (Test-Path $Dst)) {
        "$MarkerStart`n$SrcContent`n$MarkerEnd" | Set-Content $Dst -Encoding UTF8
        Write-Ok "Created $Label with Dev.IQ instructions."
        return
    }
    $Existing = Get-Content $Dst -Raw -Encoding UTF8
    if ($Existing -match '<!-- dev-iq:(begin|start)') {
        # Remove old block (any marker version), re-append updated content.
        $Pattern = '<!-- dev-iq:[\s\S]*?<!-- dev-iq:end -->'
        $Cleaned = [regex]::Replace($Existing, $Pattern, '').Trim()
        "$Cleaned`n`n$MarkerStart`n$SrcContent`n$MarkerEnd" | Set-Content $Dst -Encoding UTF8
        Write-Ok "Updated Dev.IQ block in existing $Label."
    } else {
        "$Existing`n`n$MarkerStart`n$SrcContent`n$MarkerEnd" | Set-Content $Dst -Encoding UTF8
        Write-Ok "Appended Dev.IQ instructions to existing $Label."
    }
}

if ($DryRun) {
    Write-Host "  [dry-run] would inject: CLAUDE.md"
    Write-Host "  [dry-run] would inject: AGENTS.md"
    Write-Host "  [dry-run] would inject: .github\copilot-instructions.md"
} else {
    Invoke-InjectMd "$PackRoot\CLAUDE.md"  "$Target\CLAUDE.md"  "CLAUDE.md"
    Invoke-InjectMd "$PackRoot\AGENTS.md"  "$Target\AGENTS.md"  "AGENTS.md"
    Invoke-InjectMd "$PackRoot\.github\copilot-instructions.md"  "$Target\.github\copilot-instructions.md"  "copilot-instructions.md"
}

# ── Trial mode: add paths to .git\info\exclude ───────────────────
if ($Mode -eq "trial") {
    if ($DryRun) {
        Write-Host "  [dry-run] would update: .git\info\exclude (trial mode entries)"
    } else {
        $ExcludePath = "$Target\.git\info\exclude"
        $ExcludeDir  = Split-Path $ExcludePath -Parent
        if (-not (Test-Path $ExcludeDir)) { New-Item -ItemType Directory -Path $ExcludeDir -Force | Out-Null }
        if (-not (Test-Path $ExcludePath)) { New-Item -ItemType File -Path $ExcludePath -Force | Out-Null }

        $ExcludeContent = Get-Content $ExcludePath -Raw -ErrorAction SilentlyContinue
        if ($ExcludeContent -match "# dev-iq") {
            Write-Warn "Trial mode entries already present in .git\info\exclude."
        } else {
            $Block = "`n# dev-iq — trial install v$PackVersion`n.github/skills/`n.github/instructions/`n.github/agents/`n.github/copilot-instructions.md`n.claude/agents/`n.claude/skills.md`n.dev-iq/`nCLAUDE.md`nAGENTS.md"
            if ($Hooks) { $Block += "`nhooks/" }
            Add-Content $ExcludePath $Block -Encoding UTF8
            Write-Ok "Dev.IQ paths added to .git\info\exclude (invisible to git)."
        }
    }
}

# ── Create artifact store ─────────────────────────────────────────
foreach ($sub in @('adrs','rollback-plans','user-stories','pr-reviews','signals')) {
    $dir = "$Target\.dev-iq\artifacts\$sub"
    if ($DryRun) {
        Write-Host "  [dry-run] would create: .dev-iq\artifacts\$sub"
    } elseif (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Copy-PackFile "$PackRoot\.dev-iq\artifacts\.gitignore" "$Target\.dev-iq\artifacts\.gitignore" $false
Copy-PackFile "$PackRoot\.dev-iq\artifacts\README.md"  "$Target\.dev-iq\artifacts\README.md"  $false
if (-not $DryRun) { Write-Ok "Artifact store created : .dev-iq\artifacts\" }

# ── Write install manifest ────────────────────────────────────────
if ($DryRun) {
    Write-Host "  [dry-run] would write: .dev-iq\.install-manifest.json"
} else {
    $ManifestDir = "$Target\.dev-iq"
    if (-not (Test-Path $ManifestDir)) { New-Item -ItemType Directory -Path $ManifestDir -Force | Out-Null }

    $ManifestData = [ordered]@{
        version         = $PackVersion
        installed_at    = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
        mode            = $Mode
        pack_source     = $PackRoot
        hooks_installed = $Hooks.IsPresent
        is_upgrade      = $IsUpgrade
        detected        = [ordered]@{
            tracker   = $DetectedTracker
            vcs       = $DetectedVcs
            language  = $DetectedLang
            framework = $DetectedFramework
        }
    }
    $ManifestData | ConvertTo-Json -Depth 5 | Set-Content $ManifestPath -Encoding UTF8
    Write-Ok "Manifest written : .dev-iq\.install-manifest.json"
}

# ── Summary ───────────────────────────────────────────────────────
if ($DryRun) {
    Write-Host ""
    Write-Log "Dry run complete. Re-run without -DryRun to apply."
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "  Dev.IQ $PackVersion is ready." -ForegroundColor Green
    Write-Host "  Open Copilot Chat, select Dev-IQ, type /explain-code. That's it." -ForegroundColor Green
    Write-Host ""
    if ($DetectedLang) {
        $DetectedLine = "  Detected: $DetectedLang"
        if ($DetectedFramework) { $DetectedLine += " / $DetectedFramework" }
        if ($DetectedTracker)   { $DetectedLine += " | $DetectedTracker" }
        Write-Host $DetectedLine
    } else {
        Write-Host "  Language not detected — open .dev-iq\config.yaml and fill in stack.languages."
    }
    Write-Host ""
    if ($Mode -eq "trial") {
        Write-Host "  When you're ready to share: run bootstrap.ps1 -Target '$Target' -Graduate"
        Write-Host ""
    }
}
