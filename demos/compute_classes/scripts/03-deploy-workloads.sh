#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${DEMO_DIR}/infra/common.sh"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Deploy dos Workloads (Standard vs Autopilot vs Custom)${NC}"
echo -e "${BLUE}======================================================${NC}"

# 1. Deploy do Dashboard
echo -e "${GREEN}[1/4] Fazendo deploy do Dashboard Web...${NC}"
sed "s|IMAGE_PLACEHOLDER|${DASHBOARD_IMAGE}|g" "${DEMO_DIR}/k8s/04-dashboard.yaml" | kubectl apply -f -

# 2. Deploy do Workload Standard (Manual Pool)
echo -e "${GREEN}[2/4] Fazendo deploy do Workload Standard (Manual)...${NC}"
kubectl apply -f "${DEMO_DIR}/k8s/01-standard-workload.yaml"

# 3. Deploy do Workload Autopilot Serverless
echo -e "${GREEN}[3/4] Fazendo deploy do Workload Autopilot Serverless...${NC}"
kubectl apply -f "${DEMO_DIR}/k8s/02-autopilot-general.yaml"

# 4. Deploy do Workload Customizado (Spot com Fallback)
echo -e "${GREEN}[4/4] Fazendo deploy do Workload Customizado (Spot + Fallback)...${NC}"
kubectl apply -f "${DEMO_DIR}/k8s/03-custom-spot-fallback.yaml"

echo -e "\n${GREEN}✔ Todos os workloads foram submetidos com sucesso!${NC}"
echo -e "O GKE agora provisionará dinamicamente os nós adequados para cada ComputeClass."
echo -e "Execute ${YELLOW}./04-open-dashboard.sh${NC} para acompanhar visualmente no navegador ou ${YELLOW}./05-watch-nodes.sh${NC} no terminal.\n"
