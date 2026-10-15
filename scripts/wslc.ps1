<#
.SYNOPSIS
    Start, stop or update the Acceliance Graph-RAG stack with WSL containers (wslc).

.DESCRIPTION
    For Windows without Docker Desktop: needs WSL 3.0.1 or later, which ships the
    `wslc` container CLI. wslc has no Compose support yet, so this script does what
    docker-compose.yaml does, one container at a time: same images, same variables,
    same ./data folders, one private network, one published port.

    Start   creates .env with generated secrets when missing, creates ./data and the
            network, (re)creates the four containers in order and waits for the web edge.
    Stop    stops the four containers (web edge first, databases last). ./data is kept.
    Update  pulls the images named in .env (also refreshes moving tags such as :latest),
            then recreates the containers.
    Status  lists the containers.
    Logs    prints the logs of one container (-Service).

    Idempotent: run Start again after editing .env.

.PARAMETER Action
    Start (default), Stop, Update, Status or Logs.

.PARAMETER Service
    With -Action Logs: web, api, neo4j or qdrant (default api).

.EXAMPLE
    .\scripts\wslc.ps1
.EXAMPLE
    .\scripts\wslc.ps1 Stop
.EXAMPLE
    .\scripts\wslc.ps1 Update
.EXAMPLE
    .\scripts\wslc.ps1 Logs -Service neo4j
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Start', 'Stop', 'Update', 'Status', 'Logs')]
    [string]$Action = 'Start',
    [ValidateSet('web', 'api', 'neo4j', 'qdrant')]
    [string]$Service = 'api'
)

# Not "Stop": wslc may write progress to stderr, which Windows PowerShell 5.1 would
# turn into a terminating NativeCommandError. Failures are detected with
# $LASTEXITCODE after every native call.
$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$Network    = 'graphrag-net'
# Stop order: web edge first, databases last.
$Containers = 'graphrag-web', 'graphrag-api', 'graphrag-neo4j', 'graphrag-qdrant'

function Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "WARNING: $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }
function New-Secret {
    $chars = [char[]]((48..57) + (65..90) + (97..122))
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

# Run wslc, fail with a message on a non-zero exit code.
function Invoke-Wslc([string]$what, [string[]]$wslcArgs) {
    & wslc @wslcArgs
    if ($LASTEXITCODE -ne 0) { Fail "$what failed (wslc $($wslcArgs[0..1] -join ' ') ...)." }
}

# Turn an ordered map of variables into  -e NAME=value  arguments.
function EnvArgs($map) {
    $out = @()
    foreach ($k in $map.Keys) { $out += '-e'; $out += "$k=$($map[$k])" }
    $out
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
if (-not (Get-Command wslc -ErrorAction SilentlyContinue)) {
    Fail "wslc not found on PATH. It ships with WSL 3.0.1 or later: run 'wsl --update' then 'wsl --shutdown' (see DEPLOY.md §2a)."
}
wslc version *> $null
if ($LASTEXITCODE -ne 0) { Fail "wslc is installed but does not answer ('wslc version' failed). Try 'wsl --shutdown' and run again." }

# ---------------------------------------------------------------------------
# Stop / Status / Logs need no configuration
# ---------------------------------------------------------------------------
function Stop-Stack {
    foreach ($c in $Containers) { wslc container stop $c *> $null }
}
function Remove-Stack {
    foreach ($c in $Containers) { wslc container stop $c *> $null; wslc container rm $c *> $null }
}

switch ($Action) {
    'Stop' {
        Step "Stopping the stack (./data is kept)"
        Stop-Stack
        wslc container list --all
        exit 0
    }
    'Status' { wslc container list --all; exit $LASTEXITCODE }
    'Logs'   { wslc container logs "graphrag-$Service"; exit $LASTEXITCODE }
}

# ---------------------------------------------------------------------------
# .env — create with generated secrets, or validate (same rules as up.ps1)
# ---------------------------------------------------------------------------
if (-not (Test-Path .env)) {
    Step "Creating .env from .env.example with generated secrets"
    $content = Get-Content .env.example -Raw
    $content = $content -replace '(?m)^NEO4J_PASSWORD=.*$', ("NEO4J_PASSWORD=" + (New-Secret))
    $content = $content -replace '(?m)^QDRANT_API_KEY=.*$',  ("QDRANT_API_KEY="  + (New-Secret))
    [IO.File]::WriteAllText((Join-Path $Root '.env'), $content, (New-Object Text.UTF8Encoding($false)))
    Write-Host "    .env written. Keep it: it holds the database secrets."
}

$envMap = @{}
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') { $envMap[$Matches[1]] = $Matches[2].Trim() }
}
# Value from .env, or the docker-compose.yaml default when the line is absent.
function V([string]$name, [string]$default = '') {
    if ($envMap.ContainsKey($name) -and $envMap[$name] -ne '') { $envMap[$name] } else { $default }
}

if (-not (V NEO4J_PASSWORD)) { Fail "NEO4J_PASSWORD is empty in .env." }
if (-not (V QDRANT_API_KEY)) { Fail "QDRANT_API_KEY is empty in .env." }
if ((V NEO4J_PASSWORD) -match '[\$`"\\]') { Fail 'NEO4J_PASSWORD must not contain $ ` " or \ .' }
if (-not (V GRAPHRAG_API_IMAGE) -or -not (V GRAPHRAG_WEB_IMAGE)) { Fail "GRAPHRAG_API_IMAGE / GRAPHRAG_WEB_IMAGE are not set in .env." }
if ((V AUTH_COOKIE_SECURE 'true') -eq 'true') {
    Write-Host "    AUTH_COOKIE_SECURE=true: the site must be served over HTTPS (reverse-proxy\). Set false for an HTTP pilot."
}

$QdrantImage = "qdrant/qdrant:$(V QDRANT_TAG 'v1.15.5')"
$Neo4jImage  = "neo4j:$(V NEO4J_TAG '5.26-community')"
$ApiImage    = V GRAPHRAG_API_IMAGE
$WebImage    = V GRAPHRAG_WEB_IMAGE
$Bind        = V GRAPHRAG_HTTP_BIND '0.0.0.0'
$Port        = V GRAPHRAG_HTTP_PORT '8080'

# ---------------------------------------------------------------------------
# Update: pull the images first (a moving tag such as :latest is never
# re-pulled by `wslc run` once present locally)
# ---------------------------------------------------------------------------
if ($Action -eq 'Update') {
    Step "Pulling the images named in .env"
    foreach ($img in $ApiImage, $WebImage, $Neo4jImage, $QdrantImage) {
        Write-Host "    $img"
        wslc image pull $img
        if ($LASTEXITCODE -ne 0) {
            # Fallback for a wslc build without `image pull`: drop the local copy
            # so that `wslc run` below pulls the current one.
            Warn "'wslc image pull $img' failed; removing the local image so that start-up pulls it again."
            Remove-Stack
            wslc image rm $img *> $null
        }
    }
}

# ---------------------------------------------------------------------------
# Data folders and network
# ---------------------------------------------------------------------------
foreach ($d in 'data\api', 'data\qdrant', 'data\neo4j\data', 'data\neo4j\logs', 'data\neo4j\import') {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
}
$Data = (Resolve-Path data).Path

# Already present on a second run: the error is expected and ignored.
wslc network create $Network *> $null

# ---------------------------------------------------------------------------
# (Re)create the containers, in dependency order
# ---------------------------------------------------------------------------
Step "Removing the previous containers, if any (./data is kept)"
Remove-Stack

Step "Starting Qdrant (evidence store, no published port)"
Invoke-Wslc "Starting Qdrant" (@('run', '-d', '--name', 'graphrag-qdrant', '--network', $Network) + (EnvArgs ([ordered]@{
    QDRANT__SERVICE__API_KEY   = V QDRANT_API_KEY
    QDRANT__TELEMETRY_DISABLED = 'true'
})) + @('-v', "$Data\qdrant:/qdrant/storage", $QdrantImage))

Step "Starting Neo4j (facts store, no published port)"
Invoke-Wslc "Starting Neo4j" (@('run', '-d', '--name', 'graphrag-neo4j', '--network', $Network) + (EnvArgs ([ordered]@{
    NEO4J_AUTH                                     = "neo4j/$(V NEO4J_PASSWORD)"
    NEO4J_server_memory_heap_initial__size         = V NEO4J_HEAP_INITIAL '1G'
    NEO4J_server_memory_heap_max__size             = V NEO4J_HEAP_MAX '2G'
    NEO4J_server_memory_pagecache_size             = V NEO4J_PAGECACHE '1G'
    NEO4J_server_config_strict__validation_enabled = 'false'
    NEO4J_dbms_usage__report_enabled               = 'false'
})) + @(
    '-v', "$Data\neo4j\data:/data",
    '-v', "$Data\neo4j\logs:/logs",
    '-v', "$Data\neo4j\import:/var/lib/neo4j/import",
    $Neo4jImage))

Step "Waiting for Neo4j (up to 3 min; the first run also pulls the images)"
$ready = $false
for ($i = 0; $i -lt 36; $i++) {
    if ((wslc container logs graphrag-neo4j 2>$null) -match 'Started\.') { $ready = $true; break }
    Start-Sleep -Seconds 5
}
if (-not $ready) { Fail "Neo4j did not start. Inspect with:  .\scripts\wslc.ps1 Logs -Service neo4j" }

Step "Starting graphrag-api (internal only)"
# Database hosts are the container names on the private network.
Invoke-Wslc "Starting graphrag-api" (@('run', '-d', '--name', 'graphrag-api', '--network', $Network) + (EnvArgs ([ordered]@{
    NEO4J_URI                       = 'bolt://graphrag-neo4j:7687'
    NEO4J_USER                      = 'neo4j'
    NEO4J_PASSWORD                  = V NEO4J_PASSWORD
    QDRANT_URL                      = 'http://graphrag-qdrant:6333'
    QDRANT_API_KEY                  = V QDRANT_API_KEY
    QDRANT_ON_DISK_VECTORS          = V QDRANT_ON_DISK_VECTORS 'false'
    GRAPHRAG_ALLOW_UNSECURED_QDRANT = V GRAPHRAG_ALLOW_UNSECURED_QDRANT 'false'
    GRAPHRAG_DATA_DIR               = '/data'
    GRAPHRAG_MAX_UPLOAD_MB          = V GRAPHRAG_MAX_UPLOAD_MB '50'
    GRAPHRAG_MAX_PAGES              = V GRAPHRAG_MAX_PAGES '500'
    GRAPHRAG_OCR_LANGS              = V GRAPHRAG_OCR_LANGS 'fra+eng'
    GRAPHRAG_RETENTION_DAYS         = V GRAPHRAG_RETENTION_DAYS '0'
    AGENT_MAX_ITERS                 = V AGENT_MAX_ITERS '10'
    AGENT_MAX_TOKENS                = V AGENT_MAX_TOKENS '4096'
    AUTH_COOKIE_SECURE              = V AUTH_COOKIE_SECURE 'true'
    AUTH_SESSION_TTL_SECONDS        = V AUTH_SESSION_TTL_SECONDS '43200'
    MCP_ENABLED                     = V MCP_ENABLED
    MCP_ALLOWED_HOSTS               = V MCP_ALLOWED_HOSTS
    MCP_ALLOWED_ORIGINS             = V MCP_ALLOWED_ORIGINS
    TZ                              = V TZ 'Europe/Paris'
})) + @('-v', "$Data\api:/data", $ApiImage))

Step "Starting graphrag-web (the only published port)"
Invoke-Wslc "Starting graphrag-web" (@('run', '-d', '--name', 'graphrag-web', '--network', $Network,
    '-p', "${Bind}:${Port}:80") + (EnvArgs ([ordered]@{
    GRAPHRAG_API_UPSTREAM = 'http://graphrag-api:8000'
    AUTH_MODE             = 'standalone'
})) + @($WebImage))

# ---------------------------------------------------------------------------
# Wait for the web edge to answer
# ---------------------------------------------------------------------------
$probeHost = if ($Bind -eq '0.0.0.0') { 'localhost' } else { $Bind }
$url = "http://${probeHost}:${Port}"
Step "Waiting for $url (up to 2 min)"
$up = $false
for ($i = 0; $i -lt 24; $i++) {
    try {
        Invoke-WebRequest -Uri "$url/" -UseBasicParsing -TimeoutSec 5 | Out-Null
        $up = $true; break
    } catch { Start-Sleep -Seconds 5 }
}
wslc container list

if (-not $up) {
    Warn "graphrag-web does not answer yet. Inspect with:  .\scripts\wslc.ps1 Logs -Service api   (or -Service web)"
    exit 1
}

Step "Graph-RAG is up:  $url"
Write-Host "    First visit: create the administrator account, then Admin > AI settings, then Model."
Write-Host "    Stop: .\scripts\wslc.ps1 Stop    Update images: .\scripts\wslc.ps1 Update"
if ($Action -eq 'Update') { Write-Host "    Free the previous image layers with:  wslc image prune" }
