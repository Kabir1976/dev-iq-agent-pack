# skill-improve-session-start.ps1 — fires at session start (PowerShell).
# Loads past correction lessons and outputs them as context for the agent.
# Always exits 0.

$ErrorActionPreference = 'SilentlyContinue'

$PackRoot   = if ($env:DI_PACK_ROOT) { $env:DI_PACK_ROOT } else {
    (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent)
}
$SessionId   = if ($env:CLAUDE_SESSION_ID) { $env:CLAUDE_SESSION_ID } else { $PID.ToString() }
$LessonsFile = Join-Path $PackRoot 'hooks\state\dismissed-lessons.json'
$SessionLog  = Join-Path $PackRoot "hooks\state\session-${SessionId}.jsonl"

. (Join-Path $PSScriptRoot 'lib\json-utils.ps1')

# ---------------------------------------------------------------------------
# 1. Output dismissed lessons as numbered context lines
# ---------------------------------------------------------------------------
if (Test-Path $LessonsFile) {
    try {
        $data = Get-Content $LessonsFile -Raw | ConvertFrom-Json
        $lessons = @($data.dismissed)
        if ($lessons.Count -gt 0) {
            Write-Host ''
            Write-Host '[DI Hindsight] Correction patterns from previous sessions:'
            $i = 1
            foreach ($l in $lessons) {
                Write-Host "  ${i}. [$($l.id)] $($l.lesson)"
                $i++
            }
            Write-Host ''
        }
    } catch { }
}

# ---------------------------------------------------------------------------
# 2. Record session start in session log
# ---------------------------------------------------------------------------
$Ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
Jsonl-Append -File $SessionLog `
    -Line "{`"ts`":`"$Ts`",`"event`":`"session.start`",`"session_id`":`"$SessionId`"}"

# ---------------------------------------------------------------------------
# 3. Emit telemetry
# ---------------------------------------------------------------------------
& (Join-Path $PSScriptRoot 'track-telemetry.ps1') -EventType 'session.start'

exit 0
