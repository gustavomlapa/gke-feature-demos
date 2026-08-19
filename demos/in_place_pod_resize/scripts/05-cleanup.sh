#!/usr/bin/env bash
# ==============================================================================
# 05-cleanup.sh: Remove os recursos criados para a demo in_place_pod_resize
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="$(cd "${DEMO_DIR}/../../infra" && pwd)"

# shellcheck disable=SC1091
source "${INFRA_DIR}/common.sh"

echo -e "${YELLOW}Removendo recursos da demo In-Place Pod Resize...${NC}"

kubectl delete pod java-startup-resize-demo --ignore-not-found=true
kubectl delete service java-startup-resize-service --ignore-not-found=true

echo -e "${GREEN}✔ Limpeza da demo concluída com sucesso.${NC}"
