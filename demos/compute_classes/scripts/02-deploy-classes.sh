#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${DEMO_DIR}/infra/common.sh"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Aplicando Recursos de Compute Class no GKE           ${NC}"
echo -e "${BLUE}======================================================${NC}"

echo -e "${GREEN}Aplicando manifest k8s/00-compute-classes.yaml...${NC}"
kubectl apply -f "${DEMO_DIR}/k8s/00-compute-classes.yaml"

echo -e "\n${CYAN}--- Compute Classes Configuradas ---${NC}"
kubectl get computeclass || true

echo -e "\n${GREEN}✔ Compute Classes registradas no cluster!${NC}\n"
