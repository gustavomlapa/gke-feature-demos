#!/usr/bin/env bash
# ==============================================================================
# Script para conectar o kubectl ao cluster GKE existente
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

echo -e "${BLUE}Obtendo credenciais do cluster ${CLUSTER_NAME} (${REGION})...${NC}"
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
    --region="${REGION}" \
    --project="${PROJECT_ID}"

echo -e "${GREEN}✔ Contexto do kubectl atualizado com sucesso!${NC}"
kubectl cluster-info
