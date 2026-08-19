#!/usr/bin/env bash
# ==============================================================================
# Script para criar a infraestrutura dedicada da Demo 2: GKE Standard com Compute Classes
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Provisionamento do Cluster GKE Standard (Compute Classes)${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "Projeto GCP:       ${YELLOW}${PROJECT_ID}${NC}"
echo -e "Região:            ${YELLOW}${REGION}${NC}"
echo -e "Cluster (Standard):${YELLOW}${CLUSTER_NAME}${NC}"
echo -e "Artifact Registry: ${YELLOW}${ARTIFACT_REGISTRY_REPO}${NC}"
echo -e "Canal GKE:         ${YELLOW}${RELEASE_CHANNEL}${NC}"
echo -e "------------------------------------------------------"

# 1. Configurar projeto ativo no gcloud
echo -e "${GREEN}[1/5] Configurando projeto ativo no gcloud...${NC}"
gcloud config set project "${PROJECT_ID}" --quiet

# 2. Habilitar APIs necessárias
echo -e "${GREEN}[2/5] Habilitando APIs necessárias (GKE, Artifact Registry, Cloud Build)...${NC}"
gcloud services enable     container.googleapis.com     artifactregistry.googleapis.com     cloudbuild.googleapis.com     --project="${PROJECT_ID}"

# 3. Criar repositório no Artifact Registry se não existir
echo -e "${GREEN}[3/5] Verificando repositório no Artifact Registry...${NC}"
if gcloud artifacts repositories describe "${ARTIFACT_REGISTRY_REPO}" --location="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    echo -e "Repositório ${ARTIFACT_REGISTRY_REPO} já existe."
else
    echo -e "Criando repositório Docker ${ARTIFACT_REGISTRY_REPO} em ${REGION}..."
    gcloud artifacts repositories create "${ARTIFACT_REGISTRY_REPO}"         --repository-format=docker         --location="${REGION}"         --description="Docker repository para demos do GKE"         --project="${PROJECT_ID}"
fi

# 4. Criar cluster GKE Standard com suporte a Compute Classes se não existir
echo -e "${GREEN}[4/5] Verificando cluster GKE Standard...${NC}"
if gcloud container clusters describe "${CLUSTER_NAME}" --region="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    echo -e "Cluster ${CLUSTER_NAME} já existe em ${REGION}."
else
    echo -e "Criando cluster GKE Standard ${CLUSTER_NAME} (Release Channel: ${RELEASE_CHANNEL}, Default Compute Class habilitado)..."
    gcloud container clusters create "${CLUSTER_NAME}"         --region="${REGION}"         --release-channel="${RELEASE_CHANNEL}"         --num-nodes=1         --enable-autoscaling         --min-nodes=1         --max-nodes=5         --enable-autoupgrade         --enable-autorepair         --enable-default-compute-class         --enable-dataplane-v2         --project="${PROJECT_ID}"
fi

# 5. Obter credenciais para kubectl
echo -e "${GREEN}[5/5] Obtendo credenciais de acesso para kubectl...${NC}"
gcloud container clusters get-credentials "${CLUSTER_NAME}"     --region="${REGION}"     --project="${PROJECT_ID}"

echo -e "\n${GREEN}✔ Cluster GKE Standard configurado e pronto para Compute Classes!${NC}"
echo -e "Teste a conectividade executando: ${YELLOW}kubectl get nodes${NC}\n"
