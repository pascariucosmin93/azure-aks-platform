# azure-aks-platform

Production-style Azure AKS landing zone built with Terraform.

This repository is a public, sanitized reference implementation of how I would structure an Azure platform for Kubernetes workloads using:

- Azure hub-spoke networking
- Azure Kubernetes Service
- Azure Container Registry
- Azure Key Vault
- Azure Log Analytics
- user-assigned managed identities
- Azure RBAC role assignments
- reusable Terraform modules
- multi-environment layout

No live Azure account details, subscription IDs, tenant IDs, DNS zones or secrets are included.

## What This Repository Demonstrates

- modular Terraform design for Azure
- AKS platform provisioning with reusable building blocks
- network foundation for a hub-spoke model
- identity and secret-management primitives
- production-style role assignment patterns for AKS
- operational structure for `dev` and `prod`
- CI/CD validation for Terraform code quality

## Architecture

```mermaid
flowchart LR
    user[Developers / Platform Team]

    subgraph hub[Hub]
      rgHub[Hub Resource Group]
      vnetHub[Hub VNet]
      subFirewall[Shared Services / Future Firewall Subnet]
      subBastion[Bastion / Ops Subnet]
      loga[Log Analytics]
    end

    subgraph spoke[AKS Spoke]
      rgSpoke[AKS Resource Group]
      vnetSpoke[Spoke VNet]
      subAks[AKS Subnet]
      aks[AKS Cluster]
      acr[Azure Container Registry]
      kv[Key Vault]
      uami[User Assigned Managed Identity]
    end

    user --> aks
    rgHub --> vnetHub
    rgSpoke --> vnetSpoke
    vnetHub --- vnetSpoke
    vnetSpoke --> subAks
    subAks --> aks
    aks --> acr
    aks --> kv
    aks --> loga
    uami --> aks
    vnetHub --> subFirewall
    vnetHub --> subBastion
```

## Repository Layout

- `modules/resource-group/`: resource group module
- `modules/network/`: VNet, subnets and optional peering
- `modules/acr/`: Azure Container Registry
- `modules/key-vault/`: Key Vault
- `modules/monitoring/`: Log Analytics workspace
- `modules/identity/`: user-assigned managed identity
- `modules/role-assignment/`: reusable Azure RBAC role assignment
- `modules/aks/`: AKS cluster
- `envs/dev/`: development environment composition
- `envs/prod/`: production environment composition
- `examples/minimal/`: smallest useful AKS composition
- `envs/*/backend.hcl.example`: sanitized Azure Blob backend examples
- `docs/architecture.md`: design and implementation notes
- `.github/workflows/terraform.yml`: Terraform quality workflow

## Design Goals

- clear separation between foundation and workload platform resources
- reusable modules with environment-specific composition
- minimal hardcoding
- identity-first approach
- safe public sharing

## Modules

### `resource-group`

Creates resource groups with consistent tags.

### `network`

Creates:

- virtual network
- subnets
- optional VNet peering

### `acr`

Creates a private Azure Container Registry with configurable SKU and admin access settings.

### `key-vault`

Creates an Azure Key Vault with RBAC enabled and public access controls.

### `monitoring`

Creates a Log Analytics workspace for AKS and platform observability.

### `identity`

Creates a user-assigned managed identity that can be attached to AKS or supporting services.

### `aks`

Creates:

- AKS cluster
- default node pool
- Azure CNI overlay networking
- OMS / Log Analytics integration
- managed identity integration
- optional private cluster mode
- OIDC issuer and workload identity flags

### `role-assignment`

Creates reusable Azure RBAC role assignments for access patterns such as:

- AKS kubelet identity -> `AcrPull`
- platform identity -> `Key Vault Secrets User`

## Environments

Two example environments are included:

- `envs/dev`
- `envs/prod`
- `examples/minimal`

Each environment is intentionally generic and designed for `terraform init`, `terraform fmt`, `terraform validate` and future extension into real subscriptions.

State is intended to be stored remotely in Azure Blob Storage for real deployments. The repository includes partial backend configuration and sanitized `backend.hcl.example` files for both `dev` and `prod`.

## CI/CD

GitHub Actions validates the Terraform code with:

- `terraform fmt -check`
- `terraform init -backend=false`
- `terraform validate`
- `tflint`
- `checkov`

The workflow is safe for a public repository because it does not need cloud credentials.

### Why Both TFLint and Checkov?

`TFLint` and `Checkov` solve different problems, so using both gives better coverage in CI.

- `TFLint` focuses on Terraform quality: provider usage, missing constraints, invalid arguments, naming issues, and common authoring mistakes.
- `Checkov` focuses on security and compliance: public exposure, weak defaults, missing network controls, and cloud-specific hardening gaps.

In practice, `TFLint` helps keep the code correct and maintainable, while `Checkov` helps keep the design safer and closer to production expectations.

## How To Use

1. Copy one of the environment folders.
2. Fill in `terraform.tfvars` with your own Azure values.
3. Copy `backend.hcl.example` to `backend.hcl` and replace the placeholder values with your own Azure Blob backend details.
4. Run:

```bash
cd envs/dev
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## Remote State Bootstrap

For real usage, create a dedicated Azure Storage Account and Blob container for Terraform state before the first `apply`.

- Use a separate resource group for state storage.
- Enable versioning, soft delete, and restricted network access on the storage account.
- Keep one state key per environment, for example `azure-aks-platform/dev.tfstate` and `azure-aks-platform/prod.tfstate`.
- Do not commit `backend.hcl` or any live backend values to Git.

## Notes

- This is a reference implementation, not a full enterprise landing zone.
- Add remote state, policy enforcement, private DNS and ingress layers as needed.
- Extend the AKS module with additional node pools, private DNS integration and ingress if you need a more advanced platform.

## Portfolio Positioning

This repository is meant to show cloud platform design quality:

- Azure IaC structure
- platform engineering thinking
- Kubernetes-focused cloud architecture
- reusable and maintainable Terraform layout
