# skill-improve-detect.ps1 — PostToolUse hook; detects correction edits (PowerShell).
# Reads JSON from stdin. Always exits 0.

$ErrorActionPreference = 'SilentlyContinue'

$PackRoot  = if ($env:DI_PACK_ROOT) { $env:DI_PACK_ROOT } else {
    (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent)
}
$SessionId  = if ($env:CLAUDE_SESSION_ID) { $env:CLAUDE_SESSION_ID } else { $PID.ToString() }
$SessionLog = Join-Path $PackRoot "hooks\state\session-${SessionId}.jsonl"

. (Join-Path $PSScriptRoot 'lib\json-utils.ps1')
. (Join-Path $PSScriptRoot 'lib\correction-signatures.ps1')

# ---------------------------------------------------------------------------
# 1. Parse stdin
# ---------------------------------------------------------------------------
$stdin = $input | Out-String
if ([string]::IsNullOrWhiteSpace($stdin)) {
    # Try [Console]::In
    $stdin = [Console]::In.ReadToEnd()
}
if ([string]::IsNullOrWhiteSpace($stdin)) { exit 0 }

try {
    $payload   = $stdin | ConvertFrom-Json
    $toolName  = $payload.tool_name
    $filePath  = $payload.tool_input.file_path
} catch { exit 0 }

# ---------------------------------------------------------------------------
# 2. Only act on Edit / Write / MultiEdit
# ---------------------------------------------------------------------------
if ($toolName -notin @('Edit','Write','MultiEdit')) { exit 0 }
if ([string]::IsNullOrEmpty($filePath)) { exit 0 }

# ---------------------------------------------------------------------------
# 3. Detect correction
# ---------------------------------------------------------------------------
$isCorrection = Test-CorrectionEdit -SessionLog $SessionLog -CurrFile $filePath

# ---------------------------------------------------------------------------
# 4. Append event to session JSONL log
# ---------------------------------------------------------------------------
$Ts        = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$safeFile  = $filePath -replace '\\','\\' -replace '"','\"'
$corrStr   = if ($isCorrection) { 'true' } else { 'false' }
Jsonl-Append -File $SessionLog `
    -Line "{`"ts`":`"$Ts`",`"event`":`"tool.use`",`"tool`":`"$toolName`",`"file`":`"$safeFile`",`"is_correction`":$corrStr}"

# ---------------------------------------------------------------------------
# 5. Emit telemetry
# ---------------------------------------------------------------------------
$eventType = if ($isCorrection) { 'tool.correct' } else { 'tool.detect' }
$extra     = ",`"tool`":`"$toolName`",`"file`":`"$safeFile`",`"is_correction`":$corrStr"
& (Join-Path $PSScriptRoot 'track-telemetry.ps1') -EventType $eventType -Extra $extra

exit 0
