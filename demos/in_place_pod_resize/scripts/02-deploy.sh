#!/usr/bin/env bash
# ==============================================================================
# 02-deploy.sh: Realiza o deploy do Pod Java com CPU inicial alta (2 CPUs)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="$(cd "${DEMO_DIR}/../../infra" && pwd)"

# shellcheck disable=SC1091
source "${INFRA_DIR}/common.sh"

IMAGE_TAG="${IMAGE_REPO_PATH}/java-resize-demo:latest"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Deploy do Pod Java com Alta CPU Inicial (Startup)${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "Cluster:  ${YELLOW}${CLUSTER_NAME}${NC}"
echo -e "Imagem:   ${YELLOW}${IMAGE_TAG}${NC}"
echo -e "CPU Inicial Solicitada: ${YELLOW}2 CPUs (requests/limits: 2)${NC}"
echo -e "------------------------------------------------------"

# 1. Aplicar Service
kubectl apply -f "${DEMO_DIR}/k8s/service.yaml"

# 2. Injetar a imagem no Pod manifest e aplicar
sed "s|IMAGE_PLACEHOLDER|${IMAGE_TAG}|g" "${DEMO_DIR}/k8s/pod.yaml" | kubectl apply -f -

echo -e "\nAguardando o Pod estar em estado 'Ready'..."
kubectl wait --for=condition=Ready pod/java-startup-resize-demo --timeout=180s

echo -e "\n${GREEN}✔ Pod iniciado com sucesso!${NC}"
echo -e "Recursos configurados no spec inicial:"
kubectl get pod java-startup-resize-demo -o jsonpath='{"CPU Request: "}{.spec.containers[0].resources.requests.cpu}{"\nCPU Limit:   "}{.spec.containers[0].resources.limits.cpu}{"\n"}'

echo -e "Para acompanhar o status e o warmup da JVM, execute:"
echo -e "  ${YELLOW}./demos/in_place_pod_resize/scripts/03-watch-status.sh${NC}\n"
