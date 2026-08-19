# GKE Feature Demos 🚀

Repositório modular contendo demonstrações práticas de recursos avançados do **Google Kubernetes Engine (GKE)**.

Cada demonstração é auto-contida em seu próprio diretório sob `demos/`, acompanhada de código de aplicação, manifests Kubernetes, scripts de automação e documentação passo a passo detalhada.

---

## 📋 Índice de Demonstrações

| Demo | Descrição | Status |
|---|---|---|
| [**In-Place Pod Resize**](demos/in_place_pod_resize/) | Demonstra o redimensionamento dinâmico de recursos de Pods (CPU inicial alta para warmup de JVM Java, reduzindo sem reiniciar o container com `restartCount = 0`). | ✅ Disponível |
| [**Compute Classes (Autopilot in GKE Standard)**](demos/compute_classes/) | Demonstra o uso de Compute Classes declarativas (`cloud.google.com/v1`) com suporte a Autopilot serverless em GKE Standard, hierarquias de fallback de famílias de máquina e instâncias Spot. | ✅ Disponível |

---

## ⚡ Como Começar

### 1. Pré-requisitos
- Google Cloud SDK (`gcloud` CLI instalado e autenticado)
- `kubectl` instalado
- Acesso a um projeto GCP com faturamento ativo

### 2. Configurar Variáveis de Ambiente
Copie o template de variáveis de ambiente e preencha seu `PROJECT_ID`:
```bash
cp infra/.env.example .env
```

Edite o arquivo `.env`:
```bash
PROJECT_ID="seu-projeto-gcp"
REGION="us-central1"
CLUSTER_NAME="gke-demos"
```

> 🔒 **Nota de Segurança:** O arquivo `.env` está no `.gitignore` e nunca será commitado. Nenhuma credencial ou ID de projeto deve ser incluído no repositório.

### 3. Executar as Demonstrações
Acesse a pasta da demo desejada e siga o README correspondente:
- 👉 [Guia da Demo 1: In-Place Pod Resize](demos/in_place_pod_resize/README.md) *(GKE Autopilot)*
- 👉 [Guia da Demo 2: Compute Classes](demos/compute_classes/README.md) *(Autopilot in GKE Standard)*

---

## 🧹 Limpeza de Recursos

Cada demonstração possui seus próprios scripts de limpeza e destruição em sua pasta `scripts/` (ex.: `06-cleanup.sh` e `07-destroy-infra.sh` ou `infra/delete-cluster.sh`).