# track-telemetry.ps1 — write DI Hindsight events to local log or webhook.
# Usage: .\track-telemetry.ps1 -EventType session.start [-Extra ',"key":"val"']
# Always exits 0.

param(
    [string]$EventType = 'unknown',
    [string]$Extra = ''
)

$ErrorActionPreference = 'SilentlyContinue'

$PackRoot = if ($env:DI_PACK_ROOT) { $env:DI_PACK_ROOT } else {
    (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent)
}
$ConfigFile = Join-Path $PackRoot '.dev-iq\config.yaml'
$LogFile    = Join-Path $PackRoot 'hooks\logs\skill-improve.log'
$SessionId  = if ($env:CLAUDE_SESSION_ID) { $env:CLAUDE_SESSION_ID } else { $PID.ToString() }

# ---------------------------------------------------------------------------
# Read config
# ---------------------------------------------------------------------------
function Read-ConfigValue([string]$Key) {
    if (-not (Test-Path $ConfigFile)) { return '' }
    $line = Select-String -Path $ConfigFile -Pattern "^\s*${Key}:" | Select-Object -First 1
    if (-not $line) { return '' }
    return ($line.Line -replace ".*:\s*", '').Trim().Trim('"').Trim("'")
}

$Sink       = Read-ConfigValue 'telemetry_sink'
$WebhookUrl = Read-ConfigValue 'telemetry_webhook_url'

if ($Sink -eq 'none') { exit 0 }
if ([string]::IsNullOrEmpty($Sink)) { $Sink = 'local' }

# ---------------------------------------------------------------------------
# Build payload
# ---------------------------------------------------------------------------
$Ts      = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$Payload = "{`"event`":`"$EventType`",`"session_id`":`"$SessionId`",`"ts`":`"$Ts`"$Extra}"

# ---------------------------------------------------------------------------
# Local sink
# ---------------------------------------------------------------------------
if ($Sink -eq 'local' -or $Sink -ne 'webhook') {
    try {
        $logDir = Split-Path $LogFile -Parent
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        Add-Content -Path $LogFile -Value $Payload -Encoding UTF8
    } catch { }
}

# ---------------------------------------------------------------------------
# Webhook sink
# ---------------------------------------------------------------------------
if ($Sink -eq 'webhook' -and -not [string]::IsNullOrEmpty($WebhookUrl)) {
    try {
        $job = Start-Job {
            param($url, $body)
            Invoke-RestMethod -Uri $url -Method Post -Body $body `
                -ContentType 'application/json' -TimeoutSec 3 | Out-Null
        } -ArgumentList $WebhookUrl, $Payload
        Wait-Job $job -Timeout 4 | Out-Null
        Remove-Job $job -Force | Out-Null
    } catch { }
}

exit 0
