#!/usr/bin/env bash
# ==============================================================================
# 04-resize-cpu.sh: Executa o redimensionamento in-place (redução de CPU pós-startup)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="$(cd "${DEMO_DIR}/../../infra" && pwd)"

# shellcheck disable=SC1091
source "${INFRA_DIR}/common.sh"

POD_NAME="java-startup-resize-demo"
CONTAINER_NAME="java-app"
NEW_CPU="${1:-500m}"

echo -e "${BLUE}========================================================================${NC}"
echo -e "${BLUE} Executando In-Place Pod Resize (Redução de CPU sem reiniciar o Pod)${NC}"
echo -e "${BLUE}========================================================================${NC}"
echo -e "Pod Alvo:            ${YELLOW}${POD_NAME}${NC}"
echo -e "Container:           ${YELLOW}${CONTAINER_NAME}${NC}"
echo -e "Nova CPU Solicitada: ${YELLOW}${NEW_CPU} (requests e limits)${NC}"
echo -e "------------------------------------------------------------------------"

# 1. Obter estado antes do patch
echo -e "${BLUE}Estado ANTES do Resize:${NC}"
echo -n "  • Spec CPU Requests: "
kubectl get pod "${POD_NAME}" -o jsonpath='{.spec.containers[0].resources.requests.cpu}'
echo ""
echo -n "  • Restart Count:     "
kubectl get pod "${POD_NAME}" -o jsonpath='{.status.containerStatuses[0].restartCount}'
echo ""

# 2. Executar patch in-place
echo -e "\n${YELLOW}Aplicando patch no Pod para redimensionar recursos in-place...${NC}"
PATCH_JSON=$(cat <<EOF
{
  "spec": {
    "containers": [
      {
        "name": "${CONTAINER_NAME}",
        "resources": {
          "requests": {
            "cpu": "${NEW_CPU}"
          },
          "limits": {
            "cpu": "${NEW_CPU}"
          }
        }
      }
    ]
  }
}
EOF
)

kubectl patch pod "${POD_NAME}" --patch "${PATCH_JSON}"

echo -e "\n${GREEN}✔ Patch aplicado com sucesso!${NC}"
echo -e "O Kubelet atualiza os cgroups de CPU do container no Node dinamicamente."

# 3. Exibir estado após o patch
sleep 2
echo -e "\n${BLUE}Estado APÓS o Resize:${NC}"
echo -n "  • Novo Spec CPU:   "
kubectl get pod "${POD_NAME}" -o jsonpath='{.spec.containers[0].resources.requests.cpu}'
echo ""
echo -n "  • Restart Count:   "
kubectl get pod "${POD_NAME}" -o jsonpath='{.status.containerStatuses[0].restartCount}'
echo -e " ${GREEN}(Container PERMANECEU vivo sem reiniciar!)${NC}"

echo -e "\nPara visualizar a propagação no cgroups e o status do Kubelet, acompanhe no:"
echo -e "  ${YELLOW}./demos/in_place_pod_resize/scripts/03-watch-status.sh${NC}\n"
