#!/usr/bin/env bash
# =============================================================================
#  Acceliance Graph-RAG — start (or update) the stack.
#
#    scripts/up.sh            preflight, create .env with generated secrets if
#                             missing, pull the pinned images, start, wait for
#                             health, print the URL
#    scripts/up.sh --pull-only
#
#  Idempotent: run it again after editing .env or bumping the image tags.
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

say()  { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

gen_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 33 | tr -d '+/=\n' | cut -c1-32
  else
    head -c 48 /dev/urandom | base64 | tr -d '+/=\n' | cut -c1-32
  fi
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
command -v docker >/dev/null 2>&1 || fail "docker not found on PATH (Docker Engine or Docker Desktop is required)."
docker compose version >/dev/null 2>&1 || fail "the 'docker compose' plugin is missing (Compose v2 is required)."
docker info >/dev/null 2>&1 || fail "the Docker daemon is not running or not reachable by this user."

# ---------------------------------------------------------------------------
# .env — create from the example with generated secrets, or validate
# ---------------------------------------------------------------------------
if [ ! -f .env ]; then
  say "Creating .env from .env.example with generated secrets"
  cp .env.example .env
  NEO4J_PASSWORD="$(gen_secret)"
  QDRANT_API_KEY="$(gen_secret)"
  sed -i.bak -e "s|^NEO4J_PASSWORD=.*|NEO4J_PASSWORD=${NEO4J_PASSWORD}|" \
             -e "s|^QDRANT_API_KEY=.*|QDRANT_API_KEY=${QDRANT_API_KEY}|" .env
  rm -f .env.bak
  chmod 600 .env 2>/dev/null || true
  echo "    .env written (mode 600). Keep it: it holds the database secrets."
fi

# shellcheck disable=SC1091
set -a; . ./.env; set +a
[ -n "${NEO4J_PASSWORD:-}" ] || fail "NEO4J_PASSWORD is empty in .env."
[ -n "${QDRANT_API_KEY:-}" ]  || fail "QDRANT_API_KEY is empty in .env."
case "$NEO4J_PASSWORD" in *['$`"\\']*) fail "NEO4J_PASSWORD must not contain \$ \` \" or \\ .";; esac
[ -n "${GRAPHRAG_API_IMAGE:-}" ] && [ -n "${GRAPHRAG_WEB_IMAGE:-}" ] || fail "GRAPHRAG_API_IMAGE / GRAPHRAG_WEB_IMAGE are not set in .env."
if [ "${AUTH_COOKIE_SECURE:-true}" = "true" ]; then
  echo "    AUTH_COOKIE_SECURE=true: the site must be served over HTTPS (reverse-proxy/). Set false for an HTTP pilot."
fi

# ---------------------------------------------------------------------------
# Data folders. The API image runs as UID 10001 and must write ./data/api.
# ---------------------------------------------------------------------------
mkdir -p data/api data/qdrant data/neo4j/data data/neo4j/logs data/neo4j/import
if [ "$(uname -s)" = "Linux" ]; then
  owner="$(stat -c '%u' data/api 2>/dev/null || echo 0)"
  if [ "$owner" != "10001" ] && ! su -s /bin/sh -c "test -w '$ROOT/data/api'" "#10001" 2>/dev/null; then
    if [ "$(id -u)" = "0" ]; then
      chown -R 10001:10001 data/api
    else
      warn "./data/api may not be writable by UID 10001 (the API's user). If graphrag-api fails to start, run:"
      warn "    sudo chown -R 10001:10001 $ROOT/data/api"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Pull and start
# ---------------------------------------------------------------------------
say "Pulling images (pinned tags from .env)"
docker compose pull

if [ "${1:-}" = "--pull-only" ]; then
  say "Done (--pull-only)."; exit 0
fi

say "Starting the stack"
docker compose up -d

say "Waiting for graphrag-web to be healthy (up to 3 min: Neo4j start-up is the slow part)"
for i in $(seq 1 36); do
  status="$(docker inspect -f '{{.State.Health.Status}}' graphrag-web 2>/dev/null || echo starting)"
  [ "$status" = "healthy" ] && break
  sleep 5
done
docker compose ps

if [ "$status" != "healthy" ]; then
  warn "graphrag-web is not healthy yet. Inspect with:  docker compose logs -f graphrag-api graphrag-web"
  exit 1
fi

host="${GRAPHRAG_HTTP_BIND:-0.0.0.0}"; [ "$host" = "0.0.0.0" ] && host="localhost"
say "Graph-RAG is up:  http://${host}:${GRAPHRAG_HTTP_PORT:-8080}"
echo "    First visit: create the administrator account, then Admin ▸ AI settings, then Model."
echo "    Sample model and PDFs: samples/ (see samples/README.md)."
