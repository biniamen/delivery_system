[CmdletBinding()]
param(
    [switch]$SkipMobileBuild
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'stop-local.ps1')
& (Join-Path $PSScriptRoot 'start-local.ps1') -SkipMobileBuild:$SkipMobileBuild
