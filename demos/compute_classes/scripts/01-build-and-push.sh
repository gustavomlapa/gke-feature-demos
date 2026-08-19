#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${DEMO_DIR}/infra/common.sh"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Build da Imagem do Dashboard (Compute Classes)       ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "Target Image: ${YELLOW}${DASHBOARD_IMAGE}${NC}"
echo -e "------------------------------------------------------"

if command -v gcloud >/dev/null 2>&1; then
    echo -e "${GREEN}Submetendo build para o Cloud Build...${NC}"
    gcloud builds submit "${DEMO_DIR}/app" \
        --tag="${DASHBOARD_IMAGE}" \
        --project="${PROJECT_ID}"
elif command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}Utilizando Docker local para build e push...${NC}"
    gcloud auth configure-docker "${IMAGE_REGISTRY_HOST}" --quiet
    docker build -t "${DASHBOARD_IMAGE}" "${DEMO_DIR}/app"
    docker push "${DASHBOARD_IMAGE}"
else
    echo -e "${RED}[ERRO] Nem gcloud nem docker estao disponiveis.${NC}"
    exit 1
fi

echo -e "\n${GREEN}✔ Imagem publicada com sucesso: ${YELLOW}${DASHBOARD_IMAGE}${NC}\n"
