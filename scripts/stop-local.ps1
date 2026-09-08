[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$temporaryRoot = Join-Path $projectRoot 'tmp'

function Stop-MatchingListener([int]$Port, [string[]]$CommandPatterns, [string]$Name) {
    $connections = @(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue)
    foreach ($processId in @($connections.OwningProcess | Sort-Object -Unique)) {
        if (-not $processId) { continue }
        $process = Get-CimInstance Win32_Process -Filter "ProcessId = $processId" -ErrorAction SilentlyContinue
        if ($null -eq $process) { continue }

        $isExpected = $false
        foreach ($pattern in $CommandPatterns) {
            if ($process.CommandLine -like "*$pattern*") {
                $isExpected = $true
                break
            }
        }
        if (-not $isExpected) {
            Write-Warning "Port $Port is owned by an unrelated process and was not stopped: $($process.CommandLine)"
            continue
        }

        Stop-Process -Id $processId -Force
        Write-Host "[stopped] $Name process $processId"
    }
}

Stop-MatchingListener 8080 @('http.server 8080', 'web-server --web-port 8080') 'Mobile preview'
Stop-MatchingListener 4200 @('node_modules/@angular/cli/bin/ng.js serve', 'node_modules\@angular\cli\bin\ng.js serve') 'Operations portal'
Stop-MatchingListener 5080 @('Creavers.Delivery.Api.dll') 'Backend API'

$postgresControl = 'C:\Program Files\PostgreSQL\16\bin\pg_ctl.exe'
$postgresData = Join-Path $temporaryRoot 'postgres-data'
if ((Test-Path -LiteralPath $postgresControl) -and (Test-Path -LiteralPath $postgresData)) {
    & $postgresControl stop -D $postgresData -m fast
    if ($LASTEXITCODE -eq 0) {
        Write-Host '[stopped] PostgreSQL'
    }
}

Write-Host 'Creavers local applications are stopped.'
