# Infraestrutura Compartilhada para GKE Feature Demos

Esta pasta contém os scripts de provisionamento de infraestrutura no Google Cloud (GKE Autopilot + Artifact Registry) que servem como base para todas as demonstrações deste repositório.

---

## 🔒 Segurança e Configuração

Nenhuma informação sensível (Project ID, credenciais, chaves) deve ser salva no Git. Toda a configuração é feita via arquivo local `.env`, que é ignorado pelo `.gitignore`.

### 1. Criar o arquivo `.env`

Copie o template de exemplo:
```bash
cp infra/.env.example .env
```

Abra o arquivo `.env` e preencha com o ID do seu projeto GCP e preferências:
```bash
PROJECT_ID="seu-projeto-gcp"
REGION="us-central1"
CLUSTER_NAME="gke-demos-cluster"
ARTIFACT_REGISTRY_REPO="gke-demos"
RELEASE_CHANNEL="stable"
```

---

## 🛠️ Scripts Disponíveis

| Script | Descrição |
|---|---|
| [`create-cluster.sh`](create-cluster.sh) | Habilita APIs necessárias, cria o repositório no Artifact Registry e provisiona o cluster GKE Autopilot (canal Stable). |
| [`get-credentials.sh`](get-credentials.sh) | Configura o contexto do `kubectl` local para o cluster GKE existente. |
| [`delete-cluster.sh`](delete-cluster.sh) | Deleta com confirmação o cluster GKE e opcionalmente o Artifact Registry. |

---

## 🚀 Criando o Ambiente

Execute o script de criação:
```bash
./infra/create-cluster.sh
```

Assim que a criação terminar, valide o acesso com:
```bash
kubectl get nodes
```

---

## 🧹 Destruindo o Ambiente

Quando terminar todos os testes e apresentações:
```bash
./infra/delete-cluster.sh
```
