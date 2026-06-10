# correction-signatures.ps1 — heuristics for detecting correction edits (PowerShell).
# Dot-source this file in other scripts. Functions return $true/$false.

function Test-CorrectionEdit {
    param([string]$SessionLog, [string]$CurrFile)
    $window = [int]($env:CORRECTION_WINDOW_SECONDS ?? 30)
    if (-not (Test-Path $SessionLog)) { return $false }
    if ([string]::IsNullOrEmpty($CurrFile)) { return $false }

    $cutoff = (Get-Date).AddSeconds(-$window)

    foreach ($line in (Get-Content $SessionLog -Encoding UTF8 -ErrorAction SilentlyContinue)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $entry = $line | ConvertFrom-Json
            if ($entry.file -ne $CurrFile) { continue }

            $ts = [DateTime]::Parse($entry.ts, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
            if ($ts -ge $cutoff) { return $true }
        } catch { continue }
    }
    return $false
}

function Get-SkillFromSessionLog {
    param([string]$SessionLog)
    if (-not (Test-Path $SessionLog)) { return '' }

    $skill = ''
    foreach ($line in (Get-Content $SessionLog -Encoding UTF8 -ErrorAction SilentlyContinue)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $entry = $line | ConvertFrom-Json
            if (-not [string]::IsNullOrEmpty($entry.skill)) { $skill = $entry.skill }
        } catch { continue }
    }
    return $skill
}
