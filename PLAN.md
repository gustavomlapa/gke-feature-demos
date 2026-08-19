# Plano de Desenvolvimento: GKE Feature Demos

## Demo 1: In-Place Pod Resize
- [x] Criar `.gitignore` para garantir que `.env`, chaves e credenciais nunca sejam commitados.
- [x] Criar template `.env.example` e scripts de infraestrutura GKE Autopilot (canal Stable) e Artifact Registry em `infra/` (`create-cluster.sh`, `get-credentials.sh`, `delete-cluster.sh`).
- [x] Implementar a aplicação Java de teste em `demos/in_place_pod_resize/app/` com HttpServer embutido, simulando warmup de CPU e exibindo métricas de runtime (cores, uptime, PID).
- [x] Criar `Dockerfile` multi-stage para a aplicação Java.
- [x] Criar manifests Kubernetes em `demos/in_place_pod_resize/k8s/pod.yaml` e `service.yaml` configurados com `resizePolicy` (`cpu: NotRequired`).
- [x] Criar scripts de automação da demo (`01-build-and-push.sh`, `02-deploy.sh`, `03-watch-status.sh`, `04-resize-cpu.sh`, `05-cleanup.sh`).
- [x] Escrever a documentação completa `demos/in_place_pod_resize/README.md` detalhando a teoria do In-Place Pod Resize, passo a passo de execução, saídas esperadas de terminal e como validar o zero-downtime.
- [x] Atualizar o `README.md` principal da raiz com o índice de demonstrações e instruções gerais de uso e segurança.
- [x] Atualizar a aplicação Java (`App.java`) para servir um Dashboard Web interativo em HTML/JS com métricas em tempo real (uptime contínuo, PID, Cores, heap e pulso visual).
- [x] Criar script `03-open-dashboard.sh` para abrir a interface web no navegador via `kubectl port-forward`.
- [x] Atualizar documentação `demos/in_place_pod_resize/README.md` com o roteiro de 2 telas (Web UI + Terminal).
- [x] Criar `demos/in_place_pod_resize/MANUAL_RESIZE.md` com guia de comandos manuais para copiar e colar no lugar do script 04.
- [x] Atualizar `demos/in_place_pod_resize/README.md` com referência à opção de execução manual.

## Demo 2: GKE Compute Classes (Autopilot in GKE Standard)
- [x] Criar infraestrutura dedicada da Demo 2 em `demos/compute_classes/infra/` (`common.sh`, `create-cluster.sh`, `delete-cluster.sh`, `get-credentials.sh`).
- [x] Implementar a aplicação do Dashboard Web em `demos/compute_classes/app/` (servidor HTTP em Python servindo API de cluster status e dashboard web interativo) e seu `Dockerfile`.
- [x] Criar os manifests Kubernetes em `demos/compute_classes/k8s/` (`00-compute-classes.yaml`, `01-standard-workload.yaml`, `02-autopilot-general.yaml`, `03-custom-spot-fallback.yaml`, `04-dashboard.yaml`).
- [x] Criar scripts de automação em `demos/compute_classes/scripts/` (`00-setup-infra.sh`, `01-build-and-push.sh`, `02-deploy-classes.sh`, `03-deploy-workloads.sh`, `04-open-dashboard.sh`, `05-watch-nodes.sh`, `06-cleanup.sh`, `07-destroy-infra.sh`).
- [x] Criar documentação completa da demo em `demos/compute_classes/README.md`.
- [x] Atualizar o `README.md` principal da raiz com o link e descrição da Demo 2.
