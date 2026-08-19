#!/usr/bin/env bash
# ==============================================================================
# 01-build-and-push.sh: Compila a aplicação Java e envia a imagem para o Artifact Registry
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="$(cd "${DEMO_DIR}/../../infra" && pwd)"

# Carregar variáveis do .env
# shellcheck disable=SC1091
source "${INFRA_DIR}/common.sh"

IMAGE_TAG="${IMAGE_REPO_PATH}/java-resize-demo:latest"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Build da Imagem Java via Google Cloud Build${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "Diretório do App: ${YELLOW}${DEMO_DIR}/app${NC}"
echo -e "Destino da Imagem: ${YELLOW}${IMAGE_TAG}${NC}"
echo -e "------------------------------------------------------"

# Executa o build no GCP usando Cloud Build (não necessita de daemon Docker local)
gcloud builds submit "${DEMO_DIR}/app" \
    --tag="${IMAGE_TAG}" \
    --project="${PROJECT_ID}"

echo -e "\n${GREEN}✔ Imagem compilada e publicada com sucesso em:${NC}"
echo -e "${YELLOW}${IMAGE_TAG}${NC}\n"
