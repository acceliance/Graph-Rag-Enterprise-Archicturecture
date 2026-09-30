<#
.SYNOPSIS
    Start (or update) the Acceliance Graph-RAG stack on Windows (Docker Desktop).

.DESCRIPTION
    Preflight (docker, compose v2, daemon), creates .env from .env.example with
    generated secrets when missing, validates it, creates the data folders,
    pulls the pinned images, starts the stack, waits for health, prints the URL.
    Idempotent: run again after editing .env or bumping the image tags.

.PARAMETER PullOnly
    Pull the images and stop there.

.EXAMPLE
    .\scripts\up.ps1
.EXAMPLE
    .\scripts\up.ps1 -PullOnly
#>
[CmdletBinding()]
param([switch]$PullOnly)

# Not "Stop": docker writes ordinary progress to stderr, which Windows
# PowerShell 5.1 would turn into a terminating NativeCommandError. Failures are
# detected with $LASTEXITCODE after every native call.
$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "WARNING: $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }
function New-Secret {
    $chars = [char[]]((48..57) + (65..90) + (97..122))
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Fail "docker not found on PATH (install Docker Desktop)." }
docker compose version *> $null
if ($LASTEXITCODE -ne 0) { Fail "the 'docker compose' plugin is missing (Compose v2 is required)." }
docker info *> $null
if ($LASTEXITCODE -ne 0) { Fail "the Docker daemon is not running (start Docker Desktop)." }

# ---------------------------------------------------------------------------
# .env — create with generated secrets, or validate
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
if (-not $envMap['NEO4J_PASSWORD']) { Fail "NEO4J_PASSWORD is empty in .env." }
if (-not $envMap['QDRANT_API_KEY'])  { Fail "QDRANT_API_KEY is empty in .env." }
if ($envMap['NEO4J_PASSWORD'] -match '[\$`"\\]') { Fail 'NEO4J_PASSWORD must not contain $ ` " or \ .' }
if (-not $envMap['GRAPHRAG_API_IMAGE'] -or -not $envMap['GRAPHRAG_WEB_IMAGE']) { Fail "GRAPHRAG_API_IMAGE / GRAPHRAG_WEB_IMAGE are not set in .env." }
if (($envMap['AUTH_COOKIE_SECURE'] -eq $null) -or ($envMap['AUTH_COOKIE_SECURE'] -eq 'true')) {
    Write-Host "    AUTH_COOKIE_SECURE=true: the site must be served over HTTPS (reverse-proxy\). Set false for an HTTP pilot."
}

# ---------------------------------------------------------------------------
# Data folders (Docker Desktop handles bind-mount ownership; no chown needed)
# ---------------------------------------------------------------------------
foreach ($d in 'data\api', 'data\qdrant', 'data\neo4j\data', 'data\neo4j\logs', 'data\neo4j\import') {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
}

# ---------------------------------------------------------------------------
# Pull and start
# ---------------------------------------------------------------------------
Step "Pulling images (pinned tags from .env)"
docker compose pull
if ($LASTEXITCODE -ne 0) { Fail "docker compose pull failed (check the image tags in .env and your network)." }

if ($PullOnly) { Step "Done (-PullOnly)."; exit 0 }

Step "Starting the stack"
docker compose up -d
if ($LASTEXITCODE -ne 0) { Fail "docker compose up failed." }

Step "Waiting for graphrag-web to be healthy (up to 3 min: Neo4j start-up is the slow part)"
$status = 'starting'
for ($i = 0; $i -lt 36; $i++) {
    $status = (docker inspect -f '{{.State.Health.Status}}' graphrag-web 2>$null)
    if ($status -eq 'healthy') { break }
    Start-Sleep -Seconds 5
}
docker compose ps

if ($status -ne 'healthy') {
    Warn "graphrag-web is not healthy yet. Inspect with:  docker compose logs -f graphrag-api graphrag-web"
    exit 1
}

$bind = $envMap['GRAPHRAG_HTTP_BIND']; if (-not $bind -or $bind -eq '0.0.0.0') { $bind = 'localhost' }
$port = $envMap['GRAPHRAG_HTTP_PORT']; if (-not $port) { $port = '8080' }
Step "Graph-RAG is up:  http://${bind}:${port}"
Write-Host "    First visit: create the administrator account, then Admin > AI settings, then Model."
Write-Host "    Sample model and PDFs: samples\ (see samples\README.md)."
