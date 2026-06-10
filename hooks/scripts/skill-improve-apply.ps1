# skill-improve-apply.ps1 — output dismissed lessons as agent context on demand (PowerShell).
# Can be called mid-session or at any time. Always exits 0.

$ErrorActionPreference = 'SilentlyContinue'

$PackRoot    = if ($env:DI_PACK_ROOT) { $env:DI_PACK_ROOT } else {
    (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent)
}
$LessonsFile = Join-Path $PackRoot 'hooks\state\dismissed-lessons.json'
$Prefix      = '[DI Hindsight]'

if (-not (Test-Path $LessonsFile)) { exit 0 }

try {
    $data    = Get-Content $LessonsFile -Raw | ConvertFrom-Json
    $lessons = @($data.dismissed)
    if ($lessons.Count -eq 0) {
        Write-Host "$Prefix No correction patterns recorded yet."
        exit 0
    }

    Write-Host ''
    Write-Host "$Prefix Active correction patterns ($($lessons.Count)):"
    $i = 1
    foreach ($l in $lessons) {
        Write-Host "  ${i}. [$($l.id)] $($l.lesson)  [seen $($l.frequency)x, last $($l.last_seen)]"
        $i++
    }
    Write-Host ''
} catch {
    Write-Host "$Prefix No correction patterns recorded yet."
}

exit 0
