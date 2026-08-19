#!/usr/bin/env bash
# ==============================================================================
# Helper compartilhado para carregar e validar variáveis de ambiente das demos
# ==============================================================================

set -euo pipefail

# Cores para saída no terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Localizar arquivo .env procurando na raiz ou em diretórios pais
find_env_file() {
    local curr_dir="${PWD}"
    while [[ "${curr_dir}" != "/" ]]; do
        if [[ -f "${curr_dir}/.env" ]]; then
            echo "${curr_dir}/.env"
            return 0
        elif [[ -f "${curr_dir}/infra/.env" ]]; then
            echo "${curr_dir}/infra/.env"
            return 0
        fi
        curr_dir="$(dirname "${curr_dir}")"
    done
    return 1
}

ENV_PATH="$(find_env_file || true)"

if [[ -z "${ENV_PATH}" || ! -f "${ENV_PATH}" ]]; then
    echo -e "${RED}[ERRO] Arquivo .env não foi encontrado!${NC}"
    echo -e "Por favor, crie um arquivo .env a partir do template:"
    echo -e "  ${YELLOW}cp infra/.env.example .env${NC}"
    echo -e "E preencha as variáveis como PROJECT_ID, REGION, etc."
    exit 1
fi

# Carregar variáveis do .env
# shellcheck disable=SC1090
source "${ENV_PATH}"

# Validar variáveis obrigatórias
if [[ -z "${PROJECT_ID:-}" || "${PROJECT_ID}" == "your-gcp-project-id" ]]; then
    echo -e "${RED}[ERRO] PROJECT_ID não está configurado corretamente no arquivo ${ENV_PATH}.${NC}"
    echo -e "Defina o ID do seu projeto GCP no arquivo .env."
    exit 1
fi

REGION="${REGION:-us-central1}"
CLUSTER_NAME="${CLUSTER_NAME:-gke-demos-cluster}"
ARTIFACT_REGISTRY_REPO="${ARTIFACT_REGISTRY_REPO:-gke-demos}"
RELEASE_CHANNEL="${RELEASE_CHANNEL:-stable}"

# Imagem base URI
IMAGE_REGISTRY_HOST="${REGION}-docker.pkg.dev"
IMAGE_REPO_PATH="${IMAGE_REGISTRY_HOST}/${PROJECT_ID}/${ARTIFACT_REGISTRY_REPO}"
