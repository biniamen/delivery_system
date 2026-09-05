[CmdletBinding()]
param(
    [switch]$SkipMobileBuild
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$temporaryRoot = Join-Path $projectRoot 'tmp'
$googleMapsEnabled = if ($env:GOOGLE_MAPS_ENABLED -eq 'true') { 'true' } else { 'false' }
$googleMapsServerKey = [string]$env:GOOGLE_MAPS_SERVER_API_KEY
$googleMapsBrowserKey = [string]$env:GOOGLE_MAPS_BROWSER_API_KEY
$googleMapsMapId = if ([string]::IsNullOrWhiteSpace($env:GOOGLE_MAPS_MAP_ID)) {
    'DEMO_MAP_ID'
}
else {
    $env:GOOGLE_MAPS_MAP_ID
}

function Test-LocalPort([int]$Port) {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $connection = $client.ConnectAsync('127.0.0.1', $Port)
        return $connection.Wait(500) -and $client.Connected
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Wait-ForPort([int]$Port, [string]$Name) {
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if (Test-LocalPort $Port) {
            Write-Host "[ready] $Name on port $Port"
            return
        }
        Start-Sleep -Milliseconds 500
    }
    throw "$Name did not start on port $Port. Check the log files in $temporaryRoot."
}

New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

$postgresControl = 'C:\Program Files\PostgreSQL\16\bin\pg_ctl.exe'
$postgresData = Join-Path $temporaryRoot 'postgres-data'
if (-not (Test-LocalPort 55432)) {
    if (-not (Test-Path -LiteralPath $postgresControl)) {
        throw 'PostgreSQL 16 was not found. Install it or update $postgresControl in scripts/start-local.ps1.'
    }
    & $postgresControl start -D $postgresData -l (Join-Path $temporaryRoot 'postgres.log') -o '-p 55432'
    Wait-ForPort 55432 'PostgreSQL'
}
else {
    Write-Host '[ready] PostgreSQL already running on port 55432'
}

$localDotnet = Join-Path $temporaryRoot 'dotnet-sdk-10\dotnet.exe'
$dotnet = if (Test-Path -LiteralPath $localDotnet) { $localDotnet } else { (Get-Command dotnet).Source }
$apiDirectory = Join-Path $projectRoot 'backend\src\Creavers.Delivery.Api'
if (-not (Test-LocalPort 5080)) {
    Push-Location $projectRoot
    try {
        & $dotnet build 'backend\Creavers.Delivery.slnx' -c Release --no-restore
    }
    finally {
        Pop-Location
    }

    $apiBinaryDirectory = Join-Path $apiDirectory 'bin\Release\net10.0'
    Start-Process -FilePath $dotnet `
        -ArgumentList @('Creavers.Delivery.Api.dll', '--urls', 'http://0.0.0.0:5080') `
        -WorkingDirectory $apiBinaryDirectory `
        -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $temporaryRoot 'api.out.log') `
        -RedirectStandardError (Join-Path $temporaryRoot 'api.err.log') `
        -Environment @{
            ASPNETCORE_ENVIRONMENT = 'Development'
            ConnectionStrings__Postgres = 'Host=127.0.0.1;Port=55432;Database=creavers_delivery;Username=creavers_app;Password=creavers_dev'
            Jwt__SigningKey = 'Creavers-Development-Signing-Key-2026-Must-Be-Long'
            DemoAccounts__CustomerPassword = 'CreaversDemo!2026'
            DemoAccounts__DispatcherPassword = 'CreaversDemo!2026'
            DemoAccounts__DriverPassword = 'CreaversDemo!2026'
            DemoAccounts__StoreAdminPassword = 'CreaversDemo!2026'
            GoogleMaps__Enabled = $googleMapsEnabled
            GoogleMaps__ServerApiKey = $googleMapsServerKey
            GoogleMaps__BrowserApiKey = $googleMapsBrowserKey
            GoogleMaps__MapId = $googleMapsMapId
        } | Out-Null
    Wait-ForPort 5080 'Backend API'
}
else {
    Write-Host '[ready] Backend API already running on port 5080'
}

$portalDirectory = Join-Path $projectRoot 'frontend\dispatcher-portal'
if (-not (Test-LocalPort 4200)) {
    $node = (Get-Command node).Source
    $angularCli = 'node_modules/@angular/cli/bin/ng.js'
    if (-not (Test-Path -LiteralPath (Join-Path $portalDirectory $angularCli))) {
        throw 'Angular dependencies are missing. Run pnpm install in frontend/dispatcher-portal.'
    }
    Start-Process -FilePath $node `
        -ArgumentList @($angularCli, 'serve', '--host', '0.0.0.0', '--port', '4200') `
        -WorkingDirectory $portalDirectory `
        -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $temporaryRoot 'portal.out.log') `
        -RedirectStandardError (Join-Path $temporaryRoot 'portal.err.log') | Out-Null
    Wait-ForPort 4200 'Operations portal'
}
else {
    Write-Host '[ready] Operations portal already running on port 4200'
}

$localFlutter = Join-Path $temporaryRoot 'flutter-sdk\bin\flutter.bat'
$flutter = if (Test-Path -LiteralPath $localFlutter) { $localFlutter } else { (Get-Command flutter).Source }
$mobileDirectory = Join-Path $projectRoot 'mobile'
if (-not $SkipMobileBuild) {
    $buildRoot = $projectRoot
    $temporaryDrive = $null
    if ($projectRoot.Contains(' ')) {
        foreach ($candidate in @('R', 'S', 'T', 'U', 'V')) {
            if (-not (Test-Path -LiteralPath "$candidate`:")) {
                & subst.exe "$candidate`:" $projectRoot
                if ($LASTEXITCODE -ne 0) { throw "Could not create the temporary $candidate`: drive." }
                $temporaryDrive = "$candidate`:"
                $buildRoot = "$temporaryDrive\"
                break
            }
        }
        if ($null -eq $temporaryDrive) {
            throw 'A temporary drive letter is required to build Flutter from this path. Free one of R: through V: and retry.'
        }
    }

    $flutterForBuild = if ($null -ne $temporaryDrive -and (Test-Path -LiteralPath (Join-Path $buildRoot 'tmp\flutter-sdk\bin\flutter.bat'))) {
        Join-Path $buildRoot 'tmp\flutter-sdk\bin\flutter.bat'
    }
    else {
        $flutter
    }
    $mobileBuildDirectory = Join-Path $buildRoot 'mobile'
    Push-Location $mobileBuildDirectory
    try {
        & $flutterForBuild build web --no-wasm-dry-run `
            --dart-define=API_ORIGIN=http://127.0.0.1:5080 `
            --dart-define=GOOGLE_MAPS_ENABLED=false
        if ($LASTEXITCODE -ne 0) { throw 'Flutter web build failed.' }
    }
    finally {
        Pop-Location
        if ($null -ne $temporaryDrive) {
            & subst.exe $temporaryDrive /D
        }
    }
}

if (-not (Test-LocalPort 8080)) {
    $python = (Get-Command python).Source
    Start-Process -FilePath $python `
        -ArgumentList @('-m', 'http.server', '8080', '--bind', '127.0.0.1', '--directory', 'build\web') `
        -WorkingDirectory $mobileDirectory `
        -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $temporaryRoot 'mobile.out.log') `
        -RedirectStandardError (Join-Path $temporaryRoot 'mobile.err.log') | Out-Null
    Wait-ForPort 8080 'Mobile preview'
}
else {
    Write-Host '[ready] Mobile preview already running on port 8080'
}

Write-Host ''
Write-Host 'Creavers local applications are ready:'
Write-Host '  Mobile:     http://localhost:8080'
Write-Host '  Operations: http://localhost:4200'
Write-Host '  API health: http://localhost:5080/health/live'
Write-Host 'If a browser tab was already open, press Ctrl+F5 once.'
