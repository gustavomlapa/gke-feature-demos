# Guia Passo a Passo Manual: In-Place Pod Resize via `kubectl`

Este guia foi criado para quem deseja **executar e demonstrar manualmente cada comando `kubectl`** em vez de rodar o script automatizado `04-resize-cpu.sh`.

Isso permite explicar detalhadamente para a audiência o que cada comando faz no Kubernetes e no GKE.

---

## 📋 Pré-requisitos
Certifique-se de que o Pod da demo já foi criado e está em execução:
```bash
./demos/in_place_pod_resize/scripts/02-deploy.sh
```
*(Opcional: Mantenha o Dashboard Web aberto no navegador ou o script `03-watch-status.sh` rodando em outro terminal).*

---

## 🛠️ Passo 1: Inspecionar o Estado Atual (Antes do Resize)

Mostre para a audiência que o Pod está rodando com **2 CPUs** e que o **restartCount é 0**.

### 1.1. Verificar recursos atuais configurados no Pod:
```bash
kubectl get pod java-startup-resize-demo -o jsonpath='{"CPU Desejada (Spec):   "}{.spec.containers[0].resources.requests.cpu}{"\nCPU Alocada (Status): "}{.status.containerStatuses[0].allocatedResources.cpu}{"\nRestart Count:         "}{.status.containerStatuses[0].restartCount}{"\n"}'
```

### 1.2. Verificar a política de resize configurada:
```bash
kubectl get pod java-startup-resize-demo -o jsonpath='{.spec.containers[0].resizePolicy}'
```
> **O que explicar:** *"Vejam que definimos `resizePolicy: [{resourceName: cpu, restartPolicy: NotRequired}]`. Isso autoriza o Kubernetes a alterar a cota de CPU sem reiniciar o container."*

---

## ⚡ Passo 2: Executar o Patch In-Place (Reduzindo para 500m)

Execute o comando `kubectl patch` direcionando para o sub-recurso **`--subresource=resize`**:

```bash
kubectl patch pod java-startup-resize-demo --subresource=resize --patch '
{
  "spec": {
    "containers": [
      {
        "name": "java-app",
        "resources": {
          "requests": {
            "cpu": "500m"
          },
          "limits": {
            "cpu": "500m"
          }
        }
      }
    ]
  }
}'
```

> 💡 **Nota Técnica:** No Kubernetes moderno (v1.32+ e GKE), a flag `--subresource=resize` é obrigatória porque o campo `resources` no objeto raiz do Pod é imutável, mas é mutável através do sub-recurso `/resize`.

---

## 🔍 Passo 3: Validar a Aplicação do Resize no Kubernetes

### 3.1. Verificar o novo Spec e o Status alocado no Nó:
```bash
kubectl get pod java-startup-resize-demo -o jsonpath='{"Novo Spec CPU:         "}{.spec.containers[0].resources.requests.cpu}{"\nCPU Alocada pelo Nó:   "}{.status.containerStatuses[0].allocatedResources.cpu}{"\nStatus de Transição:   "}{.status.resize}{"\nRestart Count:         "}{.status.containerStatuses[0].restartCount}{"\n"}'
```

### 3.2. Verificar a lista de Pods:
```bash
kubectl get pod java-startup-resize-demo
```
> **O que destacar na saída:** A coluna `RESTARTS` permanece rigorosamente **`0`**.

---

## 🧪 Passo 4: Provar que a Aplicação Java Não Sofreu Parada

Consulte o endpoint interno da aplicação Java diretamente no contêiner:

```bash
kubectl exec java-startup-resize-demo -- wget -qO- http://localhost:8080/status
```

Saída JSON esperada:
```json
{
  "pid": 1,
  "uptime_seconds": 125,
  "start_time": "2026-08-19T10:30:00Z",
  "available_processors": 1,
  "warmup_active": false,
  "memory": {
    "used_mb": 52,
    "total_mb": 128,
    "max_mb": 384
  }
}
```

> **O que destacar para a audiência:**
> 1. **`pid: 1`**: O processo principal nunca morreu.
> 2. **`uptime_seconds`**: O tempo continuou subindo ininterruptamente.
> 3. **`start_time`**: A data/hora de início é exatamente a mesma de quando o pod subiu.

---

## 📜 Passo 5: Inspecionar os Eventos do Kubelet (Opcional)

Para visualizar as mensagens de log do Kubelet registrando a alteração de cgroups:

```bash
kubectl describe pod java-startup-resize-demo
```
*(Procure na seção final de `Events` pela mensagem de redimensionamento do contêiner).*
