[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$frontendRoot = Join-Path $repositoryRoot 'frontend/dispatcher-portal/src/app'

$requiredPaths = @(
    'backend/Creavers.Delivery.slnx',
    'backend/src/Creavers.Delivery.Api/Program.cs',
    'backend/src/Creavers.Delivery.Infrastructure/Persistence/DeliveryDbContext.cs',
    'frontend/dispatcher-portal/angular.json',
    'frontend/dispatcher-portal/src/app/app.routes.ts',
    'docker-compose.yml',
    '.env.example'
)

foreach ($relativePath in $requiredPaths) {
    $fullPath = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Required foundation file is missing: $relativePath"
    }
}

$componentFiles = Get-ChildItem -LiteralPath $frontendRoot -Filter '*.component.ts' -Recurse
foreach ($componentFile in $componentFiles) {
    $basePath = $componentFile.FullName -replace '\.ts$', ''
    foreach ($extension in @('.html', '.css')) {
        if (-not (Test-Path -LiteralPath ($basePath + $extension) -PathType Leaf)) {
            throw "Component companion file is missing: $($basePath + $extension)"
        }
    }

    $content = Get-Content -Raw -LiteralPath $componentFile.FullName
    if ($content -match '\btemplate\s*:' -or $content -match '\bstyles\s*:') {
        throw "Inline Angular template or styles found: $($componentFile.FullName)"
    }
}

$seederContent = Get-Content -Raw -LiteralPath (
    Join-Path $repositoryRoot 'backend/src/Creavers.Delivery.Infrastructure/Persistence/DatabaseSeeder.cs'
)
$catalogueBlock = [regex]::Match(
    $seederContent,
    'var categorySeeds = new\[\]\s*\{(?<body>.*?)\n\s*\};\s*\n\s*for \(var categoryIndex',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $catalogueBlock.Success) {
    throw 'Could not locate the catalogue seed block.'
}

$productCount = [regex]::Matches(
    $catalogueBlock.Groups['body'].Value,
    '^\s+\("[^"]+",\s*"[^"]+",\s*"[^"]+",\s*\d+m\),?$',
    [System.Text.RegularExpressions.RegexOptions]::Multiline
).Count
if ($productCount -lt 36) {
    throw "Expected at least 36 seeded products; found $productCount."
}

Write-Host "Foundation checks passed: $($componentFiles.Count) Angular components have separate TS/HTML/CSS files and $productCount seeded catalogue records were found."
