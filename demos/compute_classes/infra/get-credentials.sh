#!/usr/bin/env bash
# ==============================================================================
# Script para obter o kubeconfig do cluster GKE Standard da Demo 2
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

echo -e "${BLUE}Obtendo credenciais para o cluster ${YELLOW}${CLUSTER_NAME}${BLUE} em ${YELLOW}${REGION}${BLUE}...${NC}"
gcloud container clusters get-credentials "${CLUSTER_NAME}"     --region="${REGION}"     --project="${PROJECT_ID}"

echo -e "${GREEN}✔ Contexto do kubectl atualizado com sucesso!${NC}"
kubectl get nodes
