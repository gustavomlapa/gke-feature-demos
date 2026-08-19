#!/usr/bin/env bash
# ==============================================================================
# 03-open-dashboard.sh: Abre o Dashboard Web da aplicação Java no navegador
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="$(cd "${DEMO_DIR}/../../infra" && pwd)"

# shellcheck disable=SC1091
source "${INFRA_DIR}/common.sh"

POD_NAME="java-startup-resize-demo"
PORT="8080"

echo -e "${BLUE}========================================================================${NC}"
echo -e "${BLUE} Abrindo Dashboard Web da Demo In-Place Pod Resize                       ${NC}"
echo -e "${BLUE}========================================================================${NC}"

# Verificar se o Pod existe e está rodando
if ! kubectl get pod "${POD_NAME}" >/dev/null 2>&1; then
    echo -e "${RED}[ERRO] O Pod '${POD_NAME}' não foi encontrado.${NC}"
    echo -e "Execute primeiro o deploy:"
    echo -e "  ${YELLOW}./demos/in_place_pod_resize/scripts/02-deploy.sh${NC}"
    exit 1
fi

echo -e "Iniciando encaminhamento de porta (port-forward) para o Pod ${YELLOW}${POD_NAME}:${PORT}${NC}..."
kubectl port-forward pod/"${POD_NAME}" "${PORT}:${PORT}" >/dev/null 2>&1 &
PF_PID=$!

# Função de limpeza ao encerrar
cleanup() {
    echo -e "\n${YELLOW}Encerrando port-forward (PID: ${PF_PID})...${NC}"
    kill "${PF_PID}" 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# Aguardar port-forward conectar
sleep 2

URL="http://localhost:${PORT}"
echo -e "${GREEN}✔ Dashboard disponível em: ${YELLOW}${URL}${NC}"
echo -e "Abrindo navegador..."

if command -v open >/dev/null 2>&1; then
    open "${URL}"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${URL}"
else
    echo -e "Acesse manualmente no seu navegador: ${YELLOW}${URL}${NC}"
fi

echo -e "\n${BLUE}Mantenha este terminal aberto durante a apresentação para sustentar a conexão.${NC}"
echo -e "Pressione [Ctrl+C] para encerrar."

# Manter o processo vivo
wait "${PF_PID}"
