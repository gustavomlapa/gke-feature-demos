#!/usr/bin/env bash
# ==============================================================================
# Script para remover o cluster GKE Standard da Demo de Compute Classes
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

echo -e "${RED}======================================================${NC}"
echo -e "${RED} ATENÇÃO: Remoção do Cluster GKE Standard da Demo 2   ${NC}"
echo -e "${RED}======================================================${NC}"
echo -e "Projeto GCP:       ${YELLOW}${PROJECT_ID}${NC}"
echo -e "Região:            ${YELLOW}${REGION}${NC}"
echo -e "Cluster a excluir: ${YELLOW}${CLUSTER_NAME}${NC}"
echo -e "------------------------------------------------------"

read -rp "Tem certeza que deseja DELETAR o cluster ${CLUSTER_NAME}? (y/N): " CONFIRM
if [[ "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}Deletando cluster ${CLUSTER_NAME}... (Isso pode levar alguns minutos)${NC}"
    gcloud container clusters delete "${CLUSTER_NAME}"         --region="${REGION}"         --project="${PROJECT_ID}"         --quiet
    echo -e "${GREEN}✔ Cluster ${CLUSTER_NAME} excluído com sucesso.${NC}"
else
    echo -e "\nOperação cancelada pelo usuário."
fi
