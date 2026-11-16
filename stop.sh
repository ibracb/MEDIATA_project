#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCH_DIR="${ROOT_DIR}/MEDIATA_orchestrator"
NODE_DIR="${ROOT_DIR}/MEDIATA_node"
FE_DIR="${ROOT_DIR}/MEDIATA_frontend"

compose_down_if_present() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0

  if [[ -f "${dir}/docker-compose.yml" ]]; then
    ( cd "$dir" && docker compose down --remove-orphans )
  elif [[ -f "${dir}/compose.yml" ]]; then
    ( cd "$dir" && docker compose -f compose.yml down --remove-orphans )
  fi
}

remove_container_if_present() {
  local name="$1"
  local timeout_s="${2:-30}"

  local containers
  containers="$(docker ps -a --format '{{.Names}}')" || return 1
  if ! grep -Fxq "$name" <<< "$containers"; then
    return 0
  fi

  docker stop -t "$timeout_s" "$name" >/dev/null
  docker rm "$name" >/dev/null
}

echo "================================================"
echo "MEDIATA - Teardown Script"
echo "================================================"
echo ""

# ---- Frontend ----
echo "[1/3] Stopping frontend..."
compose_down_if_present "$FE_DIR"
remove_container_if_present mediata-frontend
echo "✓ Frontend stopped"

# ---- Node ----
echo "[2/3] Stopping node..."
remove_container_if_present mediata-node 45
echo "✓ Node stopped"

# ---- Orchestrator stack ----
echo "[3/3] Stopping orchestrator stack..."
compose_down_if_present "$ORCH_DIR"
echo "✓ Orchestrator stack stopped"

echo ""
echo "================================================"
echo "Teardown complete."
echo "================================================"
echo ""
