#!/usr/bin/env bash
# ==============================================================================
# 03-watch-status.sh: Monitor em tempo real para visualizar o In-Place Pod Resize
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="$(cd "${DEMO_DIR}/../../infra" && pwd)"

# shellcheck disable=SC1091
source "${INFRA_DIR}/common.sh"

POD_NAME="java-startup-resize-demo"
ONCE="${1:-}"

display_status() {
    if ! kubectl get pod "${POD_NAME}" >/dev/null 2>&1; then
        echo -e "${RED}Pod '${POD_NAME}' não foi encontrado.${NC}"
        echo -e "Execute primeiro: ${YELLOW}./demos/in_place_pod_resize/scripts/02-deploy.sh${NC}"
        return 1
    fi

    local pod_json
    pod_json="$(kubectl get pod "${POD_NAME}" -o json)"

    local phase
    local node
    local restart_count
    local container_state
    local spec_cpu_req
    local spec_cpu_lim
    local status_cpu_alloc
    local resize_status

    phase="$(echo "${pod_json}" | grep -o '"phase": *"[^"]*"' | head -n1 | cut -d'"' -f4 || echo "Unknown")"
    node="$(echo "${pod_json}" | grep -o '"nodeName": *"[^"]*"' | head -n1 | cut -d'"' -f4 || echo "N/A")"
    restart_count="$(echo "${pod_json}" | grep -o '"restartCount": *[0-9]*' | head -n1 | awk '{print $2}' || echo "0")"
    
    # Extrair spec de CPU
    spec_cpu_req="$(kubectl get pod "${POD_NAME}" -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "N/A")"
    spec_cpu_lim="$(kubectl get pod "${POD_NAME}" -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null || echo "N/A")"
    
    # Extrair status/allocated resources e resize
    status_cpu_alloc="$(kubectl get pod "${POD_NAME}" -o jsonpath='{.status.containerStatuses[0].allocatedResources.cpu}' 2>/dev/null || echo "")"
    if [[ -z "${status_cpu_alloc}" ]]; then
        status_cpu_alloc="$(kubectl get pod "${POD_NAME}" -o jsonpath='{.status.containerStatuses[0].resources.requests.cpu}' 2>/dev/null || echo "${spec_cpu_req}")"
    fi

    resize_status="$(kubectl get pod "${POD_NAME}" -o jsonpath='{.status.resize}' 2>/dev/null || echo "None")"
    if [[ -z "${resize_status}" ]]; then
        resize_status="Completed / Steady"
    fi

    echo -e "${BLUE}========================================================================${NC}"
    echo -e "${BLUE}        PAINEL DE STATUS - IN-PLACE POD RESIZE DEMO (GKE)              ${NC}"
    echo -e "${BLUE}========================================================================${NC}"
    echo -e "Pod:           ${YELLOW}${POD_NAME}${NC} (Fase: ${GREEN}${phase}${NC})"
    echo -e "Node:          ${YELLOW}${node}${NC}"
    
    if [[ "${restart_count}" == "0" ]]; then
        echo -e "Restart Count: ${GREEN}${restart_count} (ZERO RESTARTS - Processo contínuo!)${NC}"
    else
        echo -e "Restart Count: ${RED}${restart_count}${NC}"
    fi

    echo -e "------------------------------------------------------------------------"
    echo -e "${YELLOW}RECURSOS CONFIGURADOS (Spec vs Status):${NC}"
    echo -e "  • Spec Desejado (requests / limits): ${BLUE}${spec_cpu_req} / ${spec_cpu_lim}${NC}"
    echo -e "  • Status Alocado no Node (Kubelet):  ${GREEN}${status_cpu_alloc}${NC}"
    echo -e "  • Status do Resize:                  ${YELLOW}${resize_status}${NC}"
    echo -e "------------------------------------------------------------------------"
    echo -e "${YELLOW}ÚLTIMOS LOGS DO POD (Heartbeat & Warmup):${NC}"
    kubectl logs "${POD_NAME}" --tail=5 2>/dev/null || true
    echo -e "${BLUE}========================================================================${NC}"
}

if [[ "${ONCE}" == "--once" ]]; then
    display_status
    exit 0
fi

echo -e "Pressione [Ctrl+C] para sair do monitoramento."
while true; do
    clear
    display_status || exit 1
    echo -e "\nAtualizando em 3 segundos... (Abra outro terminal para executar o script de resize)"
    sleep 3
done
