# skill-improve-reflect.ps1 — analyse a session log and summarise corrections (PowerShell).
# Usage: .\skill-improve-reflect.ps1 -SessionLog path\to\session.jsonl
# Outputs a human-readable summary to stdout. Always exits 0.

param([string]$SessionLog = '')

$ErrorActionPreference = 'SilentlyContinue'

if ([string]::IsNullOrEmpty($SessionLog) -or -not (Test-Path $SessionLog)) { exit 0 }

$editCount = @{}
$corrCount = @{}

foreach ($line in (Get-Content $SessionLog -Encoding UTF8 -ErrorAction SilentlyContinue)) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
        $entry = $line | ConvertFrom-Json
        $f = $entry.file
        if ([string]::IsNullOrEmpty($f)) { continue }
        $editCount[$f] = ($editCount[$f] ?? 0) + 1
        if ($entry.is_correction -eq $true) {
            $corrCount[$f] = ($corrCount[$f] ?? 0) + 1
        }
    } catch { continue }
}

$totalFiles       = $editCount.Count
$totalCorrections = ($corrCount.Values | Measure-Object -Sum).Sum ?? 0

Write-Host '[DI Hindsight] Session reflection:'
Write-Host "  Files edited : $totalFiles"
Write-Host "  Corrections  : $totalCorrections"

if ($totalCorrections -gt 0) {
    Write-Host '  Files with corrections:'
    foreach ($f in $corrCount.Keys) {
        Write-Host "    - $f ($($corrCount[$f]) correction(s))"
    }
}

exit 0
