# json-utils.ps1 — portable JSON helpers for Hindsight Hooks (PowerShell)
# No mandatory external dependencies; uses ConvertFrom-Json / ConvertTo-Json.
# All functions return $null on error to avoid interrupting the developer's workflow.

function Json-ReadField {
    param([string]$File, [string]$Key)
    if (-not (Test-Path $File)) { return $null }
    try {
        $obj = Get-Content $File -Raw | ConvertFrom-Json
        return $obj.$Key
    } catch { return $null }
}

function Json-AppendArray {
    param([string]$File, [string]$ObjectJson)
    if (-not (Test-Path $File)) {
        '{"dismissed":[]}' | Set-Content $File -Encoding UTF8
    }
    try {
        $obj = Get-Content $File -Raw | ConvertFrom-Json
        $newItem = $ObjectJson | ConvertFrom-Json
        # dismissed may not exist yet
        if ($null -eq $obj.dismissed) {
            $obj | Add-Member -NotePropertyName dismissed -NotePropertyValue @() -Force
        }
        $list = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $obj.dismissed) { $list.Add($item) }
        $list.Add($newItem)
        $obj.dismissed = $list.ToArray()
        $obj | ConvertTo-Json -Depth 10 | Set-Content $File -Encoding UTF8
    } catch { }
}

function Json-SetNested {
    param([string]$File, [string]$Key1, [string]$Key2, $Value)
    if (-not (Test-Path $File)) {
        '{"edits":{}}' | Set-Content $File -Encoding UTF8
    }
    try {
        $obj = Get-Content $File -Raw | ConvertFrom-Json
        if ($null -eq $obj.$Key1) {
            $obj | Add-Member -NotePropertyName $Key1 -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        $obj.$Key1 | Add-Member -NotePropertyName $Key2 -NotePropertyValue $Value -Force
        $obj | ConvertTo-Json -Depth 10 | Set-Content $File -Encoding UTF8
    } catch { }
}

function Jsonl-Append {
    param([string]$File, [string]$Line)
    try {
        $dir = Split-Path $File -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Add-Content -Path $File -Value $Line -Encoding UTF8
    } catch { }
}
