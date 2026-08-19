#!/usr/bin/env bash
# ==============================================================================
# Script para remover o cluster GKE e opcionalmente o repositório Artifact Registry
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

echo -e "${YELLOW}======================================================${NC}"
echo -e "${YELLOW} AVISO: Destruição do Cluster GKE ${CLUSTER_NAME}${NC}"
echo -e "${YELLOW}======================================================${NC}"
echo -e "Projeto GCP:       ${PROJECT_ID}"
echo -e "Região:            ${REGION}"
echo -e "Cluster:           ${CLUSTER_NAME}"
echo -e "Artifact Registry: ${ARTIFACT_REGISTRY_REPO}"
echo -e "------------------------------------------------------"

read -p "Tem certeza que deseja DELETAR o cluster ${CLUSTER_NAME}? (s/N): " -r CONFIRM
if [[ "${CONFIRM}" =~ ^[SsYy]$ ]]; then
    echo -e "${RED}Deletando cluster ${CLUSTER_NAME}...${NC}"
    gcloud container clusters delete "${CLUSTER_NAME}" \
        --region="${REGION}" \
        --project="${PROJECT_ID}" \
        --quiet
    echo -e "${GREEN}✔ Cluster deletado com sucesso.${NC}"
else
    echo -e "Operação cancelada pelo usuário."
    exit 0
fi

read -p "Deseja também deletar o repositório Artifact Registry '${ARTIFACT_REGISTRY_REPO}' e todas as imagens? (s/N): " -r CONFIRM_REPO
if [[ "${CONFIRM_REPO}" =~ ^[SsYy]$ ]]; then
    echo -e "${RED}Deletando repositório ${ARTIFACT_REGISTRY_REPO}...${NC}"
    gcloud artifacts repositories delete "${ARTIFACT_REGISTRY_REPO}" \
        --location="${REGION}" \
        --project="${PROJECT_ID}" \
        --quiet
    echo -e "${GREEN}✔ Repositório deletado com sucesso.${NC}"
fi
