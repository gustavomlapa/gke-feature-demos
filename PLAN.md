# Plano de Desenvolvimento: GKE Feature Demos

- [x] Criar `.gitignore` para garantir que `.env`, chaves e credenciais nunca sejam commitados.
- [x] Criar template `.env.example` e scripts de infraestrutura GKE Autopilot (canal Stable) e Artifact Registry em `infra/` (`create-cluster.sh`, `get-credentials.sh`, `delete-cluster.sh`).
- [ ] Implementar a aplicação Java de teste em `demos/in_place_pod_resize/app/` com HttpServer embutido, simulando warmup de CPU e exibindo métricas de runtime (cores, uptime, PID).
- [ ] Criar `Dockerfile` multi-stage para a aplicação Java.
- [ ] Criar manifests Kubernetes em `demos/in_place_pod_resize/k8s/pod.yaml` e `service.yaml` configurados com `resizePolicy` (`cpu: NotRequired`).
- [ ] Criar scripts de automação da demo (`01-build-and-push.sh`, `02-deploy.sh`, `03-watch-status.sh`, `04-resize-cpu.sh`, `05-cleanup.sh`).
- [ ] Escrever a documentação completa `demos/in_place_pod_resize/README.md` detalhando a teoria do In-Place Pod Resize, passo a passo de execução, saídas esperadas de terminal e como validar o zero-downtime.
- [ ] Atualizar o `README.md` principal da raiz com o índice de demonstrações e instruções gerais de uso e segurança.
