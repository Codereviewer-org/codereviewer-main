# Code Raptor Azure Infrastructure

This isolated folder provisions the Azure platform through reusable custom Terraform modules. No existing application, Kubernetes, Helm, Argo CD, or workflow files are used or modified.

## Resources

- One primary user-managed resource group
- One VNet with exactly five subnets
- Private AKS with one system node, one workload node, and one jumpbox VM by default
- WAF_v2 Application Gateway and AGIC
- Private PostgreSQL Flexible Server
- Private Key Vault
- Premium ACR with Private Link
- Standard Service Bus with a review-jobs queue
- Standard_B2s_v2 Ubuntu jumpbox with password-authenticated SSH
- Log Analytics, diagnostics, action group, and infrastructure alerts
- One hardened storage account and private container for Terraform state

AKS always creates an additional Azure-managed node resource group for its VM scale sets, disks, and load balancers. Terraform creates one primary resource group, but Azure's AKS-managed resource group cannot be avoided.

## Modules

~~~text
terraform-infrastructure/
|-- bootstrap/                    # Primary RG and remote-state storage
|-- modules/
|   |-- aks/
|   |-- application-gateway/
|   |-- container-registry/
|   |-- diagnostics/
|   |-- key-vault/
|   |-- log-analytics/
|   |-- linux-vm/
|   |-- monitoring/
|   |-- networking/
|   |-- postgresql/
|   |-- resource-group/
|   |-- service-bus/
|   +-- storage-account/
|-- backend.hcl.example
|-- terraform.tfvars.example
|-- main.tf
|-- variables.tf
|-- outputs.tf
|-- providers.tf
+-- versions.tf
~~~

## Network plan

| Subnet | Default CIDR | Purpose |
|---|---|---|
| snet-aks | 10.20.0.0/21 | AKS system and workload nodes |
| snet-application-gateway | 10.20.8.0/24 | Dedicated Application Gateway subnet |
| snet-database | 10.20.9.0/24 | Delegated PostgreSQL subnet |
| snet-private-endpoints | 10.20.10.0/24 | Key Vault and ACR private endpoints, with capacity for future endpoints |
| snet-vm | 10.20.11.0/24 | Password-accessible jumpbox and future self-hosted runner |

AKS uses service CIDR 10.0.0.0/16 and overlay pod CIDR 10.244.0.0/16, which do not overlap the VNet. The Application Gateway subnet is `/24` and delegated to `Microsoft.Network/applicationGateways`, which is required for the selected Azure CNI Overlay plus AGIC design.

## Capacity profile

| Pool | SKU | Minimum | Maximum | Purpose |
|---|---|---:|---:|---|
| system | Standard_B2s_v2 | 1 | 1 | AKS add-ons and application overflow |
| workload | Standard_B2s_v2 | 1 | 1 | Demo application pods |
| jumpbox | Standard_B2s_v2 | 1 | 1 | Private-cluster administration VM |

The default profile is reduced for a subscription with no DSv5 quota. AKS and the jumpbox use B-series by default: one B2s system node, one B2s workload node, and one B2s jumpbox. This needs 6 free regional vCPUs and 6 BS-family vCPUs.

This profile is for demo/dev. It is not enough for a comfortable 20-pod production deployment with rolling-update headroom. For that, increase quota and raise the workload node size/count again.

This is a planning baseline, not a guarantee of subscription quota or real-time Azure capacity. Run:

~~~bash
az vm list-usage --location australiaeast --output table

az vm list-skus \
  --location australiaeast \
  --resource-type virtualMachines \
  --size Standard_B2s_v2 \
  --all \
  --output table
~~~

For the current B-series demo profile, request or free at least 6 total regional vCPUs and 6 BS-family vCPUs. For production sizing, request at least 24 total regional vCPUs and 24 DSv5-family vCPUs, then switch workload_node_vm_size/system_node_vm_size back to DSv5 and increase workload_node_min_count/workload_node_max_count. The default availability_zones value is `[]` so Terraform creates non-zonal resources unless you explicitly set zones after confirming SKU support.

## State versus tfvars

The storage account holds encrypted Terraform state (tfstate), not tfvars.

Do not upload terraform.tfvars. It may contain sensitive inputs. Keep it ignored and pass secrets through protected CI variables or TF_VAR environment variables. State is protected with:

- HTTPS and TLS 1.2
- Microsoft Entra authentication
- Shared access keys disabled
- Private container access
- Blob versioning and soft deletion

## Prerequisites

- Terraform 1.8 or later
- Azure CLI
- Subscription Owner, or Contributor plus User Access Administrator
- Available Australia East quota
- Network access to the private AKS API for kubectl

~~~bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
az account show --output table
~~~

Register the required resource providers:

~~~bash
for provider in \
  Microsoft.ContainerService \
  Microsoft.Network \
  Microsoft.DBforPostgreSQL \
  Microsoft.KeyVault \
  Microsoft.ContainerRegistry \
  Microsoft.ServiceBus \
  Microsoft.Storage \
  Microsoft.Insights \
  Microsoft.OperationalInsights
do
  az provider register --namespace "$provider"
done
~~~

## 1. Bootstrap remote state

~~~bash
cd terraform-infrastructure/bootstrap
cp terraform.tfvars.example terraform.tfvars
~~~

Set subscription_id. If CI will run Terraform, set backend_principal_object_id to its service principal object ID, not client ID.

Create the backend using temporary local state:

~~~bash
terraform init -backend=false
terraform fmt -check
terraform validate
terraform plan -out bootstrap.tfplan
terraform apply bootstrap.tfplan
terraform output
terraform output -raw backend_hcl > ../backend.hcl
terraform init -migrate-state -backend-config=../backend.hcl
~~~

PowerShell can write the backend output with:

~~~powershell
terraform output -raw backend_hcl |
  Set-Content -Encoding ascii ..\backend.hcl
~~~

Keep backend.hcl out of Git.

## 2. Deploy the platform

~~~bash
cd ..
cp terraform.tfvars.example terraform.tfvars
~~~

Set subscription_id, terraform_state_storage_account_name, alert_email, and any region or sizing overrides.

Pass the database password outside the file. Pass the VM password only if `create_jumpbox_vm = true`:

~~~bash
export TF_VAR_postgresql_administrator_password='Use-A-Strong-Unique-Password'
export TF_VAR_vm_admin_password='Use-A-Strong-Unique-Password'
~~~

PowerShell:

~~~powershell
$env:TF_VAR_postgresql_administrator_password =
  'Use-A-Strong-Unique-Password'
$env:TF_VAR_vm_admin_password =
  'Use-A-Strong-Unique-Password'
~~~

Then deploy:

~~~bash
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -out platform.tfplan
terraform apply platform.tfplan
terraform output
~~~

## 3. Reach the private AKS API

By default, the stack creates a public-IP Ubuntu jumpbox. Set admin_source_cidr to your current public IP with /32; 0.0.0.0/0 is rejected.

Connect with:

~~~bash
ssh azure@"$(terraform output -raw vm_public_ip_address)"
~~~

After installing Azure CLI and kubectl on the jumpbox, retrieve the private cluster credentials:

~~~bash
az aks get-credentials \
  --resource-group rg-codereviewer-platform \
  --name "$(terraform output -raw aks_name)" \
  --overwrite-existing

kubectl get nodes
~~~

For an occasional remote check:

~~~bash
az aks command invoke \
  --resource-group rg-codereviewer-platform \
  --name "$(terraform output -raw aks_name)" \
  --command "kubectl get nodes"
~~~

The VM uses password authentication because it was explicitly requested. SSH keys are recommended for production.

## 4. Populate private Key Vault

Terraform intentionally does not manage application secret values because they would be recorded in state. From a VNet-connected host, create:

~~~bash
KEYVAULT_NAME="$(terraform output -raw key_vault_name)"

az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name AZUREOPENAIAPIKEY \
  --value "<AZURE_OPENAI_API_KEY>"

az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name DATABASEURL \
  --value "postgresql://postgress:<PASSWORD>@$(terraform output -raw postgresql_fqdn):5432/coderaptor?sslmode=require"

az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name JWT \
  --value "<LONG_RANDOM_JWT_SECRET>"
~~~

The CSI identity receives Key Vault Secrets User. Use the aks_key_vault_csi_client_id output as the Helm SecretProviderClass userAssignedIdentityID.

## ACR access

ACR has a private endpoint for AKS. Public access defaults to true so GitHub-hosted runners can push images, while the admin account stays disabled.

For fully private ACR:

1. Deploy a self-hosted runner in the VM subnet.
2. Grant its identity AcrPush.
3. Set acr_public_network_access_enabled to false.
4. Prefer GitHub OIDC over static registry credentials.

AKS receives AcrPull through its kubelet identity.

## Service Bus

The namespace uses the lower-cost Standard tier. Standard does not support Private Link, so its public endpoint is enabled. SAS/local authentication remains disabled; applications should use AKS Workload Identity with Azure Service Bus Data Sender or Data Receiver roles.

The review-jobs queue is provisioned, but the application must still be updated to publish and consume messages.

## Monitoring

Diagnostic data goes to Log Analytics for AKS, Application Gateway, ACR, Key Vault, PostgreSQL, Service Bus, state storage, and the jumpbox VM.

Email alerts cover:

- Azure Resource Health
- AKS node CPU above 80 percent
- PostgreSQL CPU above 80 percent
- PostgreSQL storage above 80 percent
- Application Gateway unhealthy backends
- Service Bus dead-lettered messages
- Jumpbox VM CPU above 80 percent

Confirm the Azure Monitor action-group email opt-in after deployment.

## Cost notes

The primary cost drivers are AKS nodes, WAF_v2 Application Gateway, Premium ACR, PostgreSQL, and Log Analytics ingestion. Service Bus uses the lower-cost Standard tier. Stop the jumpbox when unused.

## Destroy

Destroy the platform before bootstrap:

~~~bash
cd terraform-infrastructure
terraform destroy

cd bootstrap
terraform destroy -backend-config=../backend.hcl
~~~

Key Vault purge protection leaves the deleted vault recoverable for 90 days.

## Operational notes

- Application Gateway starts with a bootstrap HTTP listener. AGIC subsequently manages Kubernetes backends, probes, listeners, and routing rules.
- HTTPS requires a certificate and ingress/Application Gateway TLS configuration.
- PostgreSQL uses private VNet integration and private DNS.
- A private AKS cluster requires private DNS and network routing for administrative access.
- Commit the provider lock file after a successful terraform init.
