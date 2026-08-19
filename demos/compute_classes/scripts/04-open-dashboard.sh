#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${DEMO_DIR}/infra/common.sh"

LOCAL_PORT="8080"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE} Abrindo Dashboard Web (Compute Classes)              ${NC}"
echo -e "${BLUE}======================================================${NC}"

echo -e "${GREEN}Aguardando pod do dashboard estar pronto...${NC}"
kubectl rollout status deployment/compute-classes-dashboard --timeout=120s

# Liberar porta local se estiver em uso
if lsof -Pi :${LOCAL_PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}Porta ${LOCAL_PORT} já em uso. Liberando processo anterior...${NC}"
    kill -9 $(lsof -Pi :${LOCAL_PORT} -sTCP:LISTEN -t) 2>/dev/null || true
    sleep 1
fi

echo -e "${GREEN}Iniciando port-forward na porta ${LOCAL_PORT}...${NC}"
kubectl port-forward svc/compute-classes-dashboard-service ${LOCAL_PORT}:8080 >/dev/null 2>&1 &
PF_PID=$!

sleep 2

URL="http://localhost:${LOCAL_PORT}"
echo -e "${CYAN}Abrindo ${URL} no navegador...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "${URL}" || true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "${URL}" 2>/dev/null || true
fi

echo -e "\n${GREEN}✔ Dashboard em execução!${NC}"
echo -e "Pressione ${YELLOW}Ctrl+C${NC} para encerrar o port-forward quando terminar."

trap "kill ${PF_PID} 2>/dev/null || true; exit 0" INT TERM
wait ${PF_PID}
