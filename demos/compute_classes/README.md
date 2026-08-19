# Demo: GKE Compute Classes (Autopilot in GKE Standard)

Demonstração prática do uso de **Compute Classes** no Google Kubernetes Engine (GKE), explorando como clusters **GKE Standard** podem alavancar a experiência serverless do **Autopilot** e o provisionamento declarativo de nós com hierarquia de fallback e otimização de custo (Spot).

---

## 🎯 O que é o recurso de Compute Classes?

Historicamente, em clusters GKE Standard, equipes de plataforma precisavam gerenciar manualmente pools de nós (*node pools*), definindo tipos de máquina, tamanhos de disco, zonas e políticas de autoscaling fixas para cada perfil de workload.

Com o **Compute Classes** (`cloud.google.com/v1`), o GKE introduz um modelo declarativo de infraestrutura:
1. **Engenharia de Plataforma:** Define perfis de computação no cluster via Custom Resource (`ComputeClass`), configurando prioridades de famílias de máquinas (ex.: `n4`, `c3`, `n2`), suporte a Spot/Preemptible e regras de fallback.
2. **Desenvolvedores / Aplicações:** Apenas solicitam a classe desejada em seus Pods/Deployments através do seletor `cloud.google.com/compute-class: "<nome-da-classe>"`.
3. **GKE Autopilot / Node Provisioning:** O GKE cria, escala e gerencia dinamicamente os nós adequados, sem necessidade de criação manual de node pools.

---

## 🏗️ Cenários Demonstrados

| Cenário | Manifest / Seletor | Comportamento no GKE Standard |
| :--- | :--- | :--- |
| **1. Legado (Manual)** | *Sem seletor de classe* | Alocado no node pool Standard fixo inicial (`e2-standard-2`). |
| **2. Autopilot Serverless** | `cloud.google.com/compute-class: autopilot` | O GKE assume a gestão do nó como no Autopilot, provisionando capacidade sob demanda. |
| **3. Custom Fallback (Spot)** | `cloud.google.com/compute-class: resilient-cost-saver` | Tenta alocar em instâncias **N4 Spot** (máxima economia). Se indisponível, faz fallback automático para **N4 On-Demand** e depois **N2 On-Demand**. |

---

## 🚀 Roteiro de Execução da Demonstração

### Pré-requisitos
- Conta GCP com permissão de criação de clusters GKE e Artifact Registry.
- Arquivo `.env` configurado na raiz do repositório (`cp infra/.env.example .env`).
- Ferramentas instaladas: `gcloud`, `kubectl`.

---

### Passo 0: Criar o Cluster GKE Standard Dedicado

A partir da pasta `demos/compute_classes/scripts/`:

```bash
./00-setup-infra.sh
```

> **O que acontece:** Este script cria um cluster GKE Standard dedicado (ex.: `gke-demos-standard`) com `--enable-default-compute-class` e `--enable-autoscaling` habilitados.

---

### Passo 1: Build e Publicação do Dashboard Web

```bash
./01-build-and-push.sh
```

> **O que acontece:** Submete o build da imagem do dashboard via Cloud Build para o Artifact Registry do seu projeto.

---

### Passo 2: Registrar as Compute Classes Customizadas

```bash
./02-deploy-classes.sh
```

Manifest aplicado (`k8s/00-compute-classes.yaml`):
```yaml
apiVersion: cloud.google.com/v1
kind: ComputeClass
metadata:
  name: resilient-cost-saver
spec:
  nodePoolAutoCreation:
    enabled: true
  priorities:
    - machineFamily: n4
      spot: true
    - machineFamily: n4
      spot: false
    - machineFamily: n2
      spot: false
  whenUnsatisfiable: DoNotScaleUp
```

---

### Passo 3: Deploy dos Workloads

```bash
./03-deploy-workloads.sh
```

> **O que acontece:** Faz o deploy simultâneo de:
> 1. Dashboard Web (`compute-classes-dashboard`)
> 2. Workload Legado (`legacy-standard-workload`)
> 3. Workload Autopilot (`autopilot-serverless-workload`)
> 4. Workload Customizado (`spot-batch-fallback-workload`)

---

### Passo 4: Visualizar a Demonstração em 2 Telas

#### Tela 1: Dashboard Web Interativo
Execute o script de abertura do dashboard:
```bash
./04-open-dashboard.sh
```
Acesse `http://localhost:8080` no seu navegador para acompanhar em tempo real:
- Total de nós e pods ativos.
- Classificação visual dos nós (Standard Manual vs. Autopilot Serverless vs. Custom Spot).
- Mapeamento de cada Pod dentro do nó onde foi alocado.

#### Tela 2: Monitoramento Contínuo no Terminal
Em uma segunda aba do terminal:
```bash
./05-watch-nodes.sh
```

**Saída esperada de terminal:**
```
=== [12:00:00] GKE Standard - Estado de Nós e Compute Classes ===

1. NÓS E COMPUTE CLASSES:
NAME                                      STATUS   COMPUTE-CLASS          INSTANCE-TYPE   SPOT    ZONE
gke-standard-default-pool-abc1            Ready    <none>                 e2-standard-2   false   us-central1-a
gke-standard-autopilot-pool-xyz2          Ready    autopilot              e2-medium       false   us-central1-b
gke-standard-nap-n4-spot-987a             Ready    resilient-cost-saver   n4-standard-4   true    us-central1-a

2. WORKLOAD PODS E AGENDAMENTO:
NAME                                             COMPUTE-CLASS          STATUS    NODE                                      CPU-REQ
legacy-standard-workload-74f76b6d5f-4x2s1        <none>                 Running   gke-standard-default-pool-abc1            200m
autopilot-serverless-workload-5566fbc5c9-9r8km   autopilot              Running   gke-standard-autopilot-pool-xyz2          500m
spot-batch-fallback-workload-6d459bf65d-m2q1l    resilient-cost-saver   Running   gke-standard-nap-n4-spot-987a             1000m
```

---

### Passo 5: Limpeza e Destruição

Para remover apenas os workloads e classes criados:
```bash
./06-cleanup.sh
```

Para destruir o cluster GKE Standard dedicado da demo:
```bash
./07-destroy-infra.sh
```

---

## 📚 Referências Oficiais
- [Google Cloud Docs - About Compute Classes](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/about-compute-classes)
- [GKE Node Auto-Provisioning](https://cloud.google.com/kubernetes-engine/docs/concepts/node-auto-provisioning)
