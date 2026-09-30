<#
.SYNOPSIS
    Cold backup of the whole stack state (.\data + .env), consistent by construction.

.DESCRIPTION
    Stops the containers, zips .\data and .env into backups\graphrag-<UTC stamp>.zip
    (or -Destination), starts the containers again. Restore: see README.

.EXAMPLE
    .\scripts\backup.ps1
.EXAMPLE
    .\scripts\backup.ps1 -Destination D:\backups
#>
[CmdletBinding()]
param([string]$Destination)

$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
if (-not $Destination) { $Destination = Join-Path $Root 'backups' }
if (-not (Test-Path 'data')) { Write-Host "ERROR: no .\data folder here - nothing to back up." -ForegroundColor Red; exit 1 }
if (-not (Test-Path $Destination)) { New-Item -ItemType Directory -Force $Destination | Out-Null }

$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$out = Join-Path $Destination "graphrag-$stamp.zip"

Write-Host "==> Stopping the stack"
docker compose stop
try {
    Write-Host "==> Archiving .\data and .env to $out"
    Compress-Archive -Path (Join-Path $Root 'data'), (Join-Path $Root '.env') -DestinationPath $out -CompressionLevel Optimal
    $size = [math]::Round((Get-Item $out).Length / 1MB, 1)
    Write-Host "    $size MB written."
} finally {
    Write-Host "==> Starting the stack"
    docker compose start
}
