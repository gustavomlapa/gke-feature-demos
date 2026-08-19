#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${DEMO_DIR}/infra/common.sh"

echo -e "${YELLOW}Removendo workloads e dashboard da demo...${NC}"
kubectl delete -f "${DEMO_DIR}/k8s/01-standard-workload.yaml" --ignore-not-found=true
kubectl delete -f "${DEMO_DIR}/k8s/02-autopilot-general.yaml" --ignore-not-found=true
kubectl delete -f "${DEMO_DIR}/k8s/03-custom-spot-fallback.yaml" --ignore-not-found=true
kubectl delete -f "${DEMO_DIR}/k8s/04-dashboard.yaml" --ignore-not-found=true
kubectl delete -f "${DEMO_DIR}/k8s/00-compute-classes.yaml" --ignore-not-found=true

echo -e "${GREEN}✔ Recursos Kubernetes removidos com sucesso!${NC}"
