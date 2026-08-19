# GKE Feature Demos 🚀

Repositório modular contendo demonstrações práticas de recursos avançados do **Google Kubernetes Engine (GKE)**.

Cada demonstração é auto-contida em seu próprio diretório sob `demos/`, acompanhada de código de aplicação, manifests Kubernetes, scripts de automação e documentação passo a passo detalhada.

---

## 📋 Índice de Demonstrações

| Demo | Descrição | Status |
|---|---|---|
| [**In-Place Pod Resize**](demos/in_place_pod_resize/) | Demonstra o redimensionamento dinâmico de recursos de Pods (CPU inicial alta para warmup de JVM Java, reduzindo sem reiniciar o container com `restartCount = 0`). | ✅ Disponível |

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
CLUSTER_NAME="gke-demos-cluster"
```

> 🔒 **Nota de Segurança:** O arquivo `.env` está no `.gitignore` e nunca será commitado. Nenhuma credencial ou ID de projeto deve ser incluído no repositório.

### 3. Provisionar o Cluster GKE
Provisione o cluster base (GKE Autopilot no canal Stable + Artifact Registry) executando:
```bash
./infra/create-cluster.sh
```

### 4. Executar uma Demonstração
Acesse a pasta da demo desejada e siga o README correspondente:
- 👉 [Guia da Demo In-Place Pod Resize](demos/in_place_pod_resize/README.md)

---

## 🧹 Limpeza de Recursos

Para remover o cluster e evitar custos adicionais ao finalizar os testes:
```bash
./infra/delete-cluster.sh
```