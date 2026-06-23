# Code Raptor: Complete Application and Operations Guide

This is the canonical guide for developing, building, securing, deploying, releasing, and operating Code Raptor. Commands are shown from the repository root unless stated otherwise.

## 1. Platform overview

Code Raptor is an AI-assisted code-review platform built as five Python microservices:

| Component | Technology | Port | Container image | Responsibility |
|---|---|---:|---|---|
| Frontend | Streamlit | 8501 | `frontend` | Web UI, authentication screens, code editor, review results, and dashboards |
| Auth service | FastAPI | 8001 | `auth-service` | User registration, login, JWT generation, and user persistence |
| Execution service | FastAPI | 8002 | `execution-service` | Isolated Python, Java, and JavaScript execution plus YAML validation |
| AI service | FastAPI | 8003 | `ai-service` | Azure OpenAI code review, repository review, and image-to-code extraction |
| Review service | FastAPI | 8004 | `review-service` | Review history, repository analysis jobs, metrics, and reports |
| PostgreSQL | PostgreSQL 16 | 5432 | `postgres:16-alpine` | Users, reviews, repository jobs, metrics, and analysis data |

### Request flow

```text
User
  |
  v
Streamlit frontend :8501
  |-- authentication ----------> auth-service :8001 ------> PostgreSQL
  |-- code execution ----------> execution-service :8002
  |-- AI review ---------------> ai-service :8003 --------> Azure OpenAI
  `-- history/repository review > review-service :8004 ---> PostgreSQL
                                      |
                                      `-------------------> ai-service :8003
```

Only the frontend is exposed through ingress. Backend services use Kubernetes `ClusterIP` networking.

## 2. Repository layout

```text
.
|-- ai_service/                 # Azure OpenAI FastAPI service
|-- auth_service/               # Authentication FastAPI service
|-- execution_service/          # Code execution FastAPI service
|-- frontend/                   # Streamlit application
|-- review_service/             # Review, repository analysis, and metrics service
|-- tests/                      # Shared unit tests
|-- k8s/                        # Direct Kubernetes manifests
|-- helm/                       # Helm chart and environment values
|-- argocd/                     # Argo CD app-of-apps definitions
|-- .github/workflows/          # Reusable CI and release workflows
|-- docker-compose.yml          # Local full-stack environment
|-- README.md                   # Project introduction
`-- DOCUMENTATION.md            # This operational guide
```

The organization also uses separate repositories for each deployable concern:

| Repository | Purpose |
|---|---|
| `CodeReviewer-org/codereviewer-main` | Shared source/reference repository and reusable GitHub Actions workflows |
| `CodeReviewer-org/auth-service` | Auth service source and caller workflow |
| `CodeReviewer-org/execution-service` | Execution service source and caller workflow |
| `CodeReviewer-org/ai-service` | AI service source and caller workflow |
| `CodeReviewer-org/review-service` | Review service source and caller workflow |
| `CodeReviewer-org/frontend-service` | Frontend source and caller workflow |
| `CodeReviewer-org/platform-deployment` | Helm values, Kubernetes deployment configuration, and Argo CD definitions |
| `CodeReviewer-org/terraform` | Azure infrastructure as code |

## 3. Runtime configuration

### Application environment variables

| Variable | Used by | Description |
|---|---|---|
| `DATABASE_URL` | Auth, review | PostgreSQL connection string |
| `JWT_SECRET` | Auth | Secret used to sign authentication tokens |
| `AZURE_OPENAI_API_KEY` | AI | Azure OpenAI API credential |
| `AZURE_OPENAI_ENDPOINT` | AI | Azure OpenAI endpoint |
| `AZURE_OPENAI_DEPLOYMENT` | AI | Deployed model name |
| `AZURE_OPENAI_API_VERSION` | AI | Azure OpenAI API version |
| `AUTH_SERVICE_URL` | Frontend | Auth service base URL |
| `EXECUTION_SERVICE_URL` | Frontend | Execution service base URL |
| `AI_SERVICE_URL` | Frontend, review | AI service base URL |
| `REVIEW_SERVICE_URL` | Frontend | Review service base URL |
| `EXECUTION_TIMEOUT_SECONDS` | Execution | Maximum execution duration; default is 30 seconds |
| `LOG_LEVEL` | Backend services | Python logging level; default is `INFO` |

For Azure PostgreSQL Flexible Server, a typical connection string is:

```text
postgresql://<USER>:<PASSWORD>@<SERVER>.postgres.database.azure.com:5432/<DATABASE>?sslmode=require
```

Never commit actual passwords, tokens, API keys, or connection strings.

## 4. Local development with Docker Compose

### Prerequisites

- Docker Engine or Docker Desktop with Compose v2
- An Azure OpenAI resource and model deployment for AI features
- Available local ports `5432`, `8001` through `8004`, and `8501`

Create a root `.env` file:

```env
POSTGRES_DB=coderaptor
POSTGRES_USER=coderaptor
POSTGRES_PASSWORD=replace-me

AZURE_OPENAI_ENDPOINT=https://<RESOURCE>.openai.azure.com/
AZURE_OPENAI_API_KEY=replace-me
AZURE_OPENAI_DEPLOYMENT=gpt-4.1-mini
AZURE_OPENAI_API_VERSION=2025-01-01-preview
```

Start the complete stack:

```bash
docker compose up --build -d
docker compose ps
docker compose logs -f
```

Open the frontend at `http://localhost:8501`.

Stop the stack without deleting the database volume:

```bash
docker compose down
```

Delete containers and local PostgreSQL data:

```bash
docker compose down --volumes
```

### Local service URLs

Inside Docker Compose, containers use service DNS names:

```text
http://auth-service:8001
http://execution-service:8002
http://ai-service:8003
http://review-service:8004
```

Processes running directly on the host use `http://localhost:<port>`.

## 5. Running services without Docker

Create a Python 3.10 virtual environment and install each service's dependencies. Example for the auth service:

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r auth_service/requirements.txt
DATABASE_URL='<POSTGRES_CONNECTION_STRING>' \
JWT_SECRET='<LOCAL_DEVELOPMENT_SECRET>' \
uvicorn auth_service.main:app --host 0.0.0.0 --port 8001
```

On PowerShell, activate with `.\.venv\Scripts\Activate.ps1` and set values with `$env:VARIABLE='value'`.

Other entry points are:

```bash
uvicorn execution_service.main:app --host 0.0.0.0 --port 8002
uvicorn ai_service.main:app --host 0.0.0.0 --port 8003
uvicorn review_service.main:app --host 0.0.0.0 --port 8004
streamlit run frontend/app.py --server.port=8501 --server.address=0.0.0.0
```

## 6. Health checks and API surface

All backend services expose:

```text
GET /health
GET /ready
GET /live
GET /metrics
```

Important business endpoints:

| Service | Method and path | Purpose |
|---|---|---|
| Auth | `POST /register` | Create a user |
| Auth | `POST /login` | Authenticate a user |
| Execution | `POST /run` | Execute or validate submitted code |
| AI | `POST /review` | Review pasted code |
| AI | `POST /review/repository` | Run AI repository review |
| AI | `POST /extract` | Extract code from an uploaded image |
| Review | `GET/POST /reviews/{username}` | Read or save review history |
| Review | `DELETE /reviews/{tab_id}` | Delete a saved review |
| Review | `POST /review/repository` | Start asynchronous repository analysis |
| Review | `GET /review/status/{job_id}` | Read repository job status |
| Review | `GET /review/result/{job_id}` | Read repository job result |
| Review | `GET /api/analysis/{repository_id}` | Return combined repository analysis |

FastAPI interactive documentation is available at `/docs` on ports 8001 through 8004 when a service is reachable.

## 7. Tests and local quality checks

```bash
python -m pip install pytest ruff bandit pip-audit
python -m compileall -q auth_service execution_service ai_service review_service frontend
ruff check .
pytest -q
bandit --recursive auth_service execution_service ai_service review_service frontend
```

Dependency auditing is performed per service:

```bash
pip-audit --requirement auth_service/requirements.txt
```

The frontend currently has no automated tests, so its reusable CI workflow skips the test command while still compiling, linting, and scanning the source.

## 8. Container images and Azure Container Registry

All Dockerfiles use Python 3.10 multi-stage builds and run the application as a non-root user. The execution image additionally includes a Java runtime and Node.js; the review image includes Git for repository cloning.

Log in to ACR:

```bash
docker login <ACR_LOGIN_SERVER> --username <ACR_USERNAME> --password-stdin
```

Build images from this repository:

```bash
docker build -t <ACR_LOGIN_SERVER>/auth-service:<TAG> ./auth_service
docker build -t <ACR_LOGIN_SERVER>/execution-service:<TAG> ./execution_service
docker build -t <ACR_LOGIN_SERVER>/ai-service:<TAG> ./ai_service
docker build -t <ACR_LOGIN_SERVER>/review-service:<TAG> ./review_service
docker build -t <ACR_LOGIN_SERVER>/frontend:<TAG> ./frontend
```

Push each image with `docker push <ACR_LOGIN_SERVER>/<IMAGE>:<TAG>`.

Allow AKS to pull from ACR:

```bash
az aks update \
  --resource-group <RESOURCE_GROUP> \
  --name <AKS_CLUSTER_NAME> \
  --attach-acr <ACR_NAME>
```

## 9. Azure Key Vault integration

AKS uses the Azure Key Vault Secrets Store CSI driver. The current chart maps these exact Key Vault names:

| Azure Key Vault secret | Kubernetes secret key | Application variable |
|---|---|---|
| `AZUREOPENAIAPIKEY` | `AZURE_OPENAI_API_KEY` | `AZURE_OPENAI_API_KEY` |
| `DATABASEURL` | `DATABASE_URL` | `DATABASE_URL` |
| `JWT` | `JWT_SECRET` | `JWT_SECRET` |

Non-secret Azure OpenAI settings and internal service URLs are stored in `coderaptor-config`.

Enable the AKS add-on:

```bash
az aks enable-addons \
  --addons azure-keyvault-secrets-provider \
  --resource-group <RESOURCE_GROUP> \
  --name <AKS_CLUSTER_NAME>
```

Get its managed identity:

```bash
az aks show \
  --resource-group <RESOURCE_GROUP> \
  --name <AKS_CLUSTER_NAME> \
  --query addonProfiles.azureKeyvaultSecretsProvider.identity \
  --output table
```

If the vault uses Azure RBAC, grant its identity permission to read secrets:

```bash
KEYVAULT_SCOPE=$(az keyvault show \
  --name <KEYVAULT_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --query id -o tsv)

az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id <CSI_IDENTITY_OBJECT_ID> \
  --assignee-principal-type ServicePrincipal \
  --scope "$KEYVAULT_SCOPE"
```

For access-policy mode instead:

```bash
az keyvault set-policy \
  --name <KEYVAULT_NAME> \
  --object-id <CSI_IDENTITY_OBJECT_ID> \
  --secret-permissions get list
```

The `keyvault-secret-sync` pod mounts the CSI volume. That mount causes the provider to create the Kubernetes `kv-secret`. A `SecretProviderClass` alone does not create the Kubernetes Secret.

Verify synchronization:

```bash
kubectl get crd secretproviderclasses.secrets-store.csi.x-k8s.io
kubectl get secretproviderclass -A
kubectl get pods -n dev-codereviewer -l app=keyvault-secret-sync
kubectl get secret kv-secret -n dev-codereviewer
kubectl get secret kv-secret -n dev-codereviewer \
  -o go-template='{{range $key,$value := .data}}{{$key}}{{"\n"}}{{end}}'
```

The final command prints keys only, not secret values.

## 10. Kubernetes manifests

The `k8s/` directory deploys one environment into `codereviewer`. Apply resources in dependency order:

```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-configmap.yaml
kubectl apply -f k8s/SecretProviderClass.yaml
kubectl apply -f k8s/09-keyvault-sync.yaml
kubectl apply -f k8s/04-auth-service.yaml
kubectl apply -f k8s/05-execution-service.yaml
kubectl apply -f k8s/06-ai-service.yaml
kubectl apply -f k8s/07-review-service.yaml
kubectl apply -f k8s/08-frontend.yaml
kubectl apply -f k8s/ingress.yaml
```

Use Helm/Argo CD for environment-aware deployment. Direct manifests are primarily useful for validation and troubleshooting.

## 11. Helm deployments

The chart lives directly in `helm/`:

| Values file | Namespace | Replicas | Purpose |
|---|---|---:|---|
| `helm/values-dev.yaml` | `dev-codereviewer` | 1 | Development/test environment |
| `helm/values-prod.yaml` | `prod-codereviewer` | 2 | Production environment |
| `helm/values.yaml` | `codereviewer` | 1 | Base/manual environment |

Validate and render before deployment:

```bash
helm lint ./helm -f ./helm/values-dev.yaml
helm template code-raptor-dev ./helm -f ./helm/values-dev.yaml > rendered-dev.yaml
```

Install or upgrade development:

```bash
helm upgrade --install code-raptor-dev ./helm \
  --namespace dev-codereviewer \
  --create-namespace \
  -f ./helm/values-dev.yaml
```

Install or upgrade production:

```bash
helm upgrade --install code-raptor-prod ./helm \
  --namespace prod-codereviewer \
  --create-namespace \
  -f ./helm/values-prod.yaml
```

Inspect a release:

```bash
helm list -A
helm status code-raptor-dev -n dev-codereviewer
helm get values code-raptor-dev -n dev-codereviewer
```

Do not deploy the same environment using both direct manifests and Helm; that creates competing ownership and configuration drift.

## 12. Argo CD app-of-apps

`argocd/root-application.yaml` is the parent application. It discovers the child definitions under `argocd/applications/`:

```text
code-raptor-apps
|-- code-raptor-dev  -> branch test -> helm/values-dev.yaml  -> dev-codereviewer
`-- code-raptor-prod -> branch main -> helm/values-prod.yaml -> prod-codereviewer
```

Both child applications use automated synchronization, pruning, self-healing, and namespace creation.

Install Argo CD, then apply the root application:

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Available deployment/argocd-server \
  -n argocd --timeout=300s
kubectl apply -f argocd/root-application.yaml
```

Verify:

```bash
kubectl get applications -n argocd
kubectl get pods -n dev-codereviewer
kubectl get pods -n prod-codereviewer
```

Before applying, confirm every Argo CD `repoURL` points to the repository that actually contains `helm/` and `argocd/`. In the split-repository model this should normally be `CodeReviewer-org/platform-deployment`.

For private repositories, register repository credentials in Argo CD before syncing.

## 13. Application Gateway ingress

The Helm chart creates an ingress with class `azure-application-gateway`. It routes `/` to `frontend-service:8501` and uses Streamlit's `/_stcore/health` endpoint for the Application Gateway probe.

Verify ingress and the AGIC controller:

```bash
kubectl get ingress -n dev-codereviewer
kubectl describe ingress codereviewer-ingress -n dev-codereviewer
kubectl get pods -n kube-system | grep ingress-appgw
kubectl logs -n kube-system deployment/ingress-appgw-deployment --tail=200
```

An empty ingress address usually means AGIC is not Ready, cannot access Application Gateway, or has not completed CNI reconciliation. Fix the controller first; changing the application ingress will not repair an unhealthy controller.

## 14. Reusable GitHub Actions CI/CD

### Workflow inventory

| Workflow | Purpose |
|---|---|
| `.github/workflows/reusable-ci.yml` | Generic Python service CI and development GitOps update |
| `.github/workflows/reusable-ci-frontend.yaml` | Frontend-specific version of the same CI flow |
| `.github/workflows/reusable-release.yml` | Manual immutable-image promotion and production GitOps update |

The CI flow is:

```text
Caller push/PR
  -> checkout source
  -> install Python dependencies
  -> compile, lint, and test
  -> pip-audit, Bandit, Snyk, and optional SonarQube
  -> build container image
  -> push <ACR>/<IMAGE>:<COMMIT_SHA> on push
  -> update platform-deployment/test helm/values-dev.yaml
  -> Argo CD syncs development
  -> send SMTP notification
```

The release flow is:

```text
Manual release tag (vX.Y.Z)
  -> read the tested commit-SHA tag from development values
  -> pull that exact ACR image
  -> retag and push it as vX.Y.Z
  -> update platform-deployment/main helm/values-prod.yaml
  -> Argo CD syncs production
  -> send SMTP notification
```

No production image is rebuilt. The already-tested development image is promoted.

### Organization secrets

Create these GitHub organization secrets and grant access to the service repositories:

| Secret | Purpose |
|---|---|
| `ACR_LOGIN_SERVER` | ACR host, such as `example.azurecr.io` |
| `ACR_USERNAME` | ACR login username or service-principal client ID |
| `ACR_PASSWORD` | ACR password or service-principal secret |
| `INFRA_REPO_TOKEN` | Fine-grained PAT used to update `platform-deployment` |
| `SONAR_TOKEN` | SonarQube Cloud authentication |
| `SNYK_TOKEN` | Snyk authentication |
| `EMAIL_USERNAME` | SMTP account and notification recipient |
| `EMAIL_PASSWORD` | SMTP password or Gmail app password |

`INFRA_REPO_TOKEN` should be a fine-grained token limited to `platform-deployment` with repository Contents read/write permission. Do not give it broader organization or administration permissions.

### Caller workflow pattern

Each service repository owns a small caller workflow. A generic service CI job looks like:

```yaml
jobs:
  ci:
    if: github.event_name != 'workflow_dispatch'
    uses: CodeReviewer-org/codereviewer-main/.github/workflows/reusable-ci.yml@main
    with:
      trigger_event: ${{ github.event_name }}
      source_sha: ${{ github.event.pull_request.head.sha || github.sha }}
      service_name: auth-service
      image_name: auth-service
      helm_service_key: auth
      infra_repository: CodeReviewer-org/platform-deployment
      dev_infra_ref: test
      dev_values_path: helm/values-dev.yaml
    secrets: inherit
```

The frontend calls `.github/workflows/reusable-ci-frontend.yaml@main` and does not need to pass service, image, or Helm key because its defaults are frontend-specific. Always pass `dev_infra_ref: test` explicitly.

The manual release job calls `reusable-release.yml@main` with:

```yaml
with:
  release_tag: ${{ inputs.release_tag }}
  service_name: auth-service
  image_name: auth-service
  helm_service_key: auth
  infra_repository: CodeReviewer-org/platform-deployment
  dev_infra_ref: test
  prod_infra_ref: main
  dev_values_path: helm/values-dev.yaml
  prod_values_path: helm/values-prod.yaml
secrets: inherit
```

Use these Helm keys:

| Repository | `service_name` | `image_name` | `helm_service_key` |
|---|---|---|---|
| `auth-service` | `auth-service` | `auth-service` | `auth` |
| `execution-service` | `execution-service` | `execution-service` | `execution` |
| `ai-service` | `ai-service` | `ai-service` | `ai` |
| `review-service` | `review-service` | `review-service` | `review` |
| `frontend-service` | `frontend-service` | `frontend` | `frontend` |

## 15. Deployment verification

```bash
kubectl get nodes
kubectl get pods,svc,ingress -n dev-codereviewer
kubectl get secret kv-secret -n dev-codereviewer
kubectl rollout status deployment/auth-service -n dev-codereviewer
kubectl rollout status deployment/execution-service -n dev-codereviewer
kubectl rollout status deployment/ai-service -n dev-codereviewer
kubectl rollout status deployment/review-service -n dev-codereviewer
kubectl rollout status deployment/frontend -n dev-codereviewer
```

Test internal DNS and connectivity:

```bash
kubectl run curl-test -n dev-codereviewer --rm -i --restart=Never \
  --image=curlimages/curl -- curl -i http://auth-service:8001/health
```

Confirm a service is listening inside its container:

```bash
kubectl exec -n dev-codereviewer deployment/auth-service -- \
  python -c 'import socket; s=socket.create_connection(("127.0.0.1",8001),3); print("listening"); s.close()'
```

## 16. Troubleshooting

### `SecretProviderClass` resource mapping not found

The CSI driver CRD is missing. Enable the AKS Key Vault add-on and verify:

```bash
kubectl get crd secretproviderclasses.secrets-store.csi.x-k8s.io
```

### `kv-secret` does not exist

Check that `keyvault-secret-sync` exists and is Ready. The Secret is synchronized only while a pod mounts the CSI volume.

```bash
kubectl describe pod -n dev-codereviewer -l app=keyvault-secret-sync
```

### Key Vault mount returns HTTP 403

The client ID in `SecretProviderClass` must be the CSI add-on identity's client ID, and its object ID must have `Key Vault Secrets User` or access-policy `get/list` permissions.

### Auth or review service repeatedly restarts

Read current and previous logs:

```bash
kubectl logs -n dev-codereviewer deployment/auth-service --tail=200
kubectl logs -n dev-codereviewer deployment/auth-service --previous --tail=200
```

If PostgreSQL times out, verify its firewall/private networking and allow the AKS egress path. A pod can be marked Running during restart backoff even when the application is not listening, so test port 8001 directly.

### Azure PostgreSQL firewall rule

```bash
az postgres flexible-server firewall-rule create \
  --resource-group <RESOURCE_GROUP> \
  --server-name <POSTGRES_SERVER_NAME> \
  --name AllowAKS \
  --start-ip-address <AKS_EGRESS_IP> \
  --end-ip-address <AKS_EGRESS_IP>
```

Do not use a developer workstation IP for AKS traffic. If PostgreSQL uses a private endpoint, AKS must have appropriate VNet routing and private DNS instead of a public firewall rule.

### Pods remain Pending

```bash
kubectl describe pod <POD_NAME> -n dev-codereviewer
kubectl describe node
kubectl top nodes
kubectl top pods -n dev-codereviewer
```

`Insufficient cpu` or `Insufficient memory` means total pod requests do not fit. Reduce requests/replicas for development or add node capacity. Azure free-trial regional vCPU quota can prevent autoscaler expansion; request quota or use a region/VM SKU with available quota.

### Ingress has no address

Check AGIC readiness and logs. Controller failures such as overlay CNI reconciliation must be resolved at the AKS/Application Gateway layer.

### ACR image pull fails

```bash
kubectl describe pod <POD_NAME> -n dev-codereviewer
az aks check-acr \
  --resource-group <RESOURCE_GROUP> \
  --name <AKS_CLUSTER_NAME> \
  --acr <ACR_LOGIN_SERVER>
```

Confirm the Helm registry, repository, and tag exist in ACR.

## 17. Rollback and recovery

With Argo CD, revert the Git commit that changed the image tag. Argo CD will reconcile the cluster to the previous desired state.

For a manually managed Helm release:

```bash
helm history code-raptor-dev -n dev-codereviewer
helm rollback code-raptor-dev <REVISION> -n dev-codereviewer
```

For an emergency Kubernetes rollout rollback:

```bash
kubectl rollout undo deployment/frontend -n dev-codereviewer
```

Commit the matching GitOps correction immediately afterward, or Argo CD will restore the Git-declared version.

## 18. Security and release checklist

- Keep all secrets in Azure Key Vault or GitHub encrypted secrets.
- Never print secret values in workflow logs.
- Scope `INFRA_REPO_TOKEN` only to the deployment repository.
- Protect `main` and require pull-request review.
- Require successful lint, tests, and security scans before merge.
- Use immutable commit SHA image tags in development.
- Promote the tested SHA image to a semantic production tag; do not rebuild it.
- Keep service containers non-root.
- Use PostgreSQL TLS and restricted networking.
- Review Snyk, Bandit, pip-audit, and SonarQube findings.
- Verify Argo CD is Synced and Healthy after every release.
- Verify auth, AI, execution, review, and frontend health before announcing release completion.

## 19. Related documents

- [Project README](README.md)
- [Architecture details](CODE_RAPTOR.md)
- [Review API contracts](review_service/API_CONTRACTS.md)
- [Helm chart notes](helm/README.md)
- [AKS Key Vault notes](k8s/README_AKS_KEYVAULT.md)

When another document conflicts with this guide, verify the live YAML and workflow files; they are the source of truth.
