#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${DEMO_DIR}/infra/common.sh"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Monitoramento Contínuo: Nós e Compute Classes        ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "Pressione ${YELLOW}Ctrl+C${NC} para sair."
echo -e "------------------------------------------------------\n"

while true; do
    clear
    echo -e "${BLUE}=== [$(date +"%T")] GKE Standard - Estado de Nós e Compute Classes ===${NC}\n"
    
    echo -e "${CYAN}1. NÓS E COMPUTE CLASSES:${NC}"
    kubectl get nodes -L cloud.google.com/compute-class,node.kubernetes.io/instance-type,cloud.google.com/gke-spot,topology.kubernetes.io/zone -o wide
    
    echo -e "\n${CYAN}2. WORKLOAD PODS E AGENDAMENTO:${NC}"
    kubectl get pods -o custom-columns="NAME:.metadata.name,COMPUTE-CLASS:.spec.nodeSelector.cloud\\.google\\.com/compute-class,STATUS:.status.phase,NODE:.spec.nodeName,CPU-REQ:.spec.containers[*].resources.requests.cpu"
    
    echo -e "\n${CYAN}3. COMPUTE CLASSES REGISTRADAS:${NC}"
    kubectl get computeclass 2>/dev/null || echo "Nenhuma ComputeClass customizada encontrada"
    
    sleep 3
done
