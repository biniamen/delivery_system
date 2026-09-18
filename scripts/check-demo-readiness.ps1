[CmdletBinding()]
param(
    [string]$ApiOrigin = 'http://127.0.0.1:5080'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dotnet = Join-Path $projectRoot 'tmp\dotnet-sdk-10\dotnet.exe'
$flutter = Join-Path $projectRoot 'tmp\flutter-sdk\bin\flutter.bat'
$dart = Join-Path $projectRoot 'tmp\flutter-sdk\bin\cache\dart-sdk\bin\dart.exe'
$node = (Get-Command node).Source

if ([string]::IsNullOrWhiteSpace($env:CREAVERS_TEST_PASSWORD)) {
    throw 'Set CREAVERS_TEST_PASSWORD to the local demo password before running readiness checks.'
}
if (-not (Test-Path -LiteralPath $dotnet)) { throw "Bundled .NET SDK not found at $dotnet" }
if (-not (Test-Path -LiteralPath $flutter)) { throw "Bundled Flutter SDK not found at $flutter" }

function Invoke-Checked([string]$Name, [scriptblock]$Action) {
    Write-Host "[check] $Name"
    & $Action
    if ($LASTEXITCODE -ne 0) { throw "$Name failed with exit code $LASTEXITCODE." }
    Write-Host "[pass]  $Name"
}

function Assert-HttpOk([string]$Name, [string]$Url) {
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -ne 200) { throw "$Name returned HTTP $($response.StatusCode)." }
    Write-Host "[pass]  $Name ($Url)"
}

Push-Location $projectRoot
try {
    Invoke-Checked 'Backend tests' {
        & $dotnet test '.\backend\Creavers.Delivery.slnx' --no-restore
    }

    Push-Location '.\frontend\dispatcher-portal'
    try {
        Invoke-Checked 'Dispatcher tests' {
            & $node '.\node_modules\@angular\cli\bin\ng.js' test --watch=false
        }
        Invoke-Checked 'Dispatcher production build' {
            & $node '.\node_modules\@angular\cli\bin\ng.js' build --configuration production
        }
    }
    finally {
        Pop-Location
    }

    $temporaryDrive = $null
    foreach ($candidate in @('R', 'S', 'T', 'U', 'V')) {
        if (-not (Test-Path -LiteralPath "$candidate`:\")) {
            & subst.exe "$candidate`:" $projectRoot
            if ($LASTEXITCODE -ne 0) { throw "Could not create temporary drive $candidate`:" }
            $temporaryDrive = "$candidate`:"
            break
        }
    }
    if ($null -eq $temporaryDrive) {
        throw 'A temporary drive letter is required for Flutter. Free one of R: through V: and retry.'
    }

    try {
        $mappedRoot = "$temporaryDrive\"
        Push-Location (Join-Path $mappedRoot 'mobile')
        try {
            $mappedDart = Join-Path $mappedRoot 'tmp\flutter-sdk\bin\cache\dart-sdk\bin\dart.exe'
            $mappedFlutter = Join-Path $mappedRoot 'tmp\flutter-sdk\bin\flutter.bat'
            Invoke-Checked 'Mobile static analysis' {
                & $mappedDart analyze
            }
            Invoke-Checked 'Mobile tests' {
                & $mappedFlutter test --no-pub
            }
            Invoke-Checked 'PostgreSQL-backed delivery flow' {
                & $mappedDart run '.\tool\full_order_flow_check.dart' "--origin=$ApiOrigin"
            }
        }
        finally {
            Pop-Location
        }
    }
    finally {
        & subst.exe $temporaryDrive /D
    }

    Assert-HttpOk 'Backend health' "$ApiOrigin/health/live"
    Assert-HttpOk 'Dispatcher portal' 'http://127.0.0.1:4200/'
    Assert-HttpOk 'Mobile preview' 'http://127.0.0.1:8080/'
    Write-Host ''
    Write-Host 'DEMO READY: automated checks and the complete delivery-confirmation flow passed.'
}
finally {
    Pop-Location
}
