# skill-improve-session-end.ps1 — fires at Stop; consolidates session log (PowerShell).
# Promotes repeated correction patterns and updates edit-frequency.json.
# Always exits 0.

$ErrorActionPreference = 'SilentlyContinue'

$PackRoot    = if ($env:DI_PACK_ROOT) { $env:DI_PACK_ROOT } else {
    (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent)
}
$SessionId   = if ($env:CLAUDE_SESSION_ID) { $env:CLAUDE_SESSION_ID } else { $PID.ToString() }
$SessionLog  = Join-Path $PackRoot "hooks\state\session-${SessionId}.jsonl"
$LessonsFile = Join-Path $PackRoot 'hooks\state\dismissed-lessons.json'
$FreqFile    = Join-Path $PackRoot 'hooks\state\edit-frequency.json'
$ConfigFile  = Join-Path $PackRoot 'hooks\config\skill-improve.config.json'

. (Join-Path $PSScriptRoot 'lib\json-utils.ps1')
. (Join-Path $PSScriptRoot 'lib\correction-signatures.ps1')

# ---------------------------------------------------------------------------
# Read config
# ---------------------------------------------------------------------------
$MinCorrections   = 2
$MaxLessons       = 20
$RetentionDays    = 7
if (Test-Path $ConfigFile) {
    try {
        $cfg = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        if ($cfg.min_corrections_to_promote) { $MinCorrections = [int]$cfg.min_corrections_to_promote }
        if ($cfg.max_lessons)               { $MaxLessons      = [int]$cfg.max_lessons }
        if ($cfg.session_log_retention_days){ $RetentionDays   = [int]$cfg.session_log_retention_days }
    } catch { }
}

# ---------------------------------------------------------------------------
# 1. Bail early if no session log
# ---------------------------------------------------------------------------
if (-not (Test-Path $SessionLog)) {
    & (Join-Path $PSScriptRoot 'track-telemetry.ps1') -EventType 'session.end'
    exit 0
}

# ---------------------------------------------------------------------------
# 2. Count corrections per file
# ---------------------------------------------------------------------------
$corrCount = @{}
$skill     = ''

foreach ($line in (Get-Content $SessionLog -Encoding UTF8 -ErrorAction SilentlyContinue)) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
        $entry = $line | ConvertFrom-Json
        if (-not [string]::IsNullOrEmpty($entry.skill)) { $skill = $entry.skill }
        if ($entry.is_correction -eq $true -and -not [string]::IsNullOrEmpty($entry.file)) {
            $corrCount[$entry.file] = ($corrCount[$entry.file] ?? 0) + 1
        }
    } catch { continue }
}

$Today = (Get-Date).ToString('yyyy-MM-dd')

# ---------------------------------------------------------------------------
# 3. Promote files with >= MinCorrections to dismissed-lessons.json
# ---------------------------------------------------------------------------
if ($corrCount.Count -gt 0 -and (Test-Path $LessonsFile)) {
    try {
        $lessonsData = Get-Content $LessonsFile -Raw | ConvertFrom-Json
        $lessonsList = [System.Collections.Generic.List[object]]::new()
        foreach ($item in @($lessonsData.dismissed)) { $lessonsList.Add($item) }

        foreach ($f in $corrCount.Keys) {
            $count = $corrCount[$f]
            if ($count -lt $MinCorrections) { continue }

            # Check if lesson already exists for this file
            $existing = $lessonsList | Where-Object { $_.pattern -like "*$f*" } | Select-Object -First 1
            if ($existing) {
                $existing.frequency += $count
                $existing.last_seen  = $Today
            } elseif ($lessonsList.Count -lt $MaxLessons) {
                $id = "lesson-$(Get-Date -Format 'yyyyMMddHHmmss')-$([System.Environment]::TickCount)"
                $newLesson = [PSCustomObject]@{
                    id        = $id
                    pattern   = "repeated edit to $f"
                    lesson    = "Review $f carefully — it was re-edited $count time(s) this session."
                    frequency = $count
                    last_seen = $Today
                }
                $lessonsList.Add($newLesson)
            }
        }

        $lessonsData.dismissed = $lessonsList.ToArray()
        $lessonsData | ConvertTo-Json -Depth 10 | Set-Content $LessonsFile -Encoding UTF8
    } catch { }
}

# ---------------------------------------------------------------------------
# 4. Update edit-frequency.json for the skill seen this session
# ---------------------------------------------------------------------------
if (-not [string]::IsNullOrEmpty($skill)) {
    try {
        if (-not (Test-Path $FreqFile)) { '{"edits":{}}' | Set-Content $FreqFile -Encoding UTF8 }
        $freq = Get-Content $FreqFile -Raw | ConvertFrom-Json
        if ($null -eq $freq.edits) {
            $freq | Add-Member -NotePropertyName edits -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        $currentInv  = if ($freq.edits.$skill) { [int]$freq.edits.$skill.invocations } else { 0 }
        $currentCorr = if ($freq.edits.$skill) { [int]$freq.edits.$skill.corrections  } else { 0 }
        $newEntry = [PSCustomObject]@{
            invocations = $currentInv + 1
            corrections = $currentCorr + ($corrCount.Values | Measure-Object -Sum).Sum
        }
        $freq.edits | Add-Member -NotePropertyName $skill -NotePropertyValue $newEntry -Force
        $freq | ConvertTo-Json -Depth 10 | Set-Content $FreqFile -Encoding UTF8
    } catch { }
}

# ---------------------------------------------------------------------------
# 5. Remove session temp file
# ---------------------------------------------------------------------------
Remove-Item $SessionLog -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# 6. Prune stale session logs
# ---------------------------------------------------------------------------
$stateDir = Join-Path $PackRoot 'hooks\state'
if (Test-Path $stateDir) {
    Get-ChildItem -Path $stateDir -Filter 'session-*.jsonl' -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# 7. Emit telemetry
# ---------------------------------------------------------------------------
& (Join-Path $PSScriptRoot 'track-telemetry.ps1') -EventType 'session.end'

exit 0
