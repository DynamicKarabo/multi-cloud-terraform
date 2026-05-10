# Multi-Cloud Terraform

[![Terraform CI](https://github.com/DynamicKarabo/multi-cloud-terraform/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/DynamicKarabo/multi-cloud-terraform/actions/workflows/terraform-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-1.9%2B-844EBA?logo=terraform)](https://www.terraform.io)
[![Checkov](https://img.shields.io/badge/Checkov-Passing-2ea44f?logo=bridgecrew)](https://www.checkov.io)
[![TFLint](https://img.shields.io/badge/TFLint-AWS%20Ruleset-FF6C37?logo=terraform)](https://github.com/terraform-linters/tflint)
[![AWS](https://img.shields.io/badge/AWS-Modules-FF9900?logo=amazonaws)](https://aws.amazon.com)

**Production-grade reusable Terraform modules with multi-environment composition, validated CI pipelines, and security-by-default patterns.** A hands-on DevOps case study demonstrating infrastructure-as-code excellence — from module design principles through automated governance.

> **What this is:** A composable, extensible Terraform framework for provisioning cloud infrastructure across environments, with battle-tested CI/CD patterns, security hardening, and clear architecture decisions. Currently focused on **AWS** with an architecture designed for seamless GCP and Azure extension.

---

## Table of Contents

- [Overview &amp; Motivation](#overview--motivation)
- [Features](#features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Module Deep Dive](#module-deep-dive)
  - [VPC Module](#vpc-module)
  - [EC2 Module](#ec2-module)
  - [S3 Module](#s3-module)
- [Environment Strategy](#environment-strategy)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security &amp; Compliance](#security--compliance)
- [State Management](#state-management)
- [Architecture Decisions](#architecture-decisions)
- [Extending to GCP/Azure](#extending-to-gcpazure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Overview &amp; Motivation

This repository exists to demonstrate **production-grade Infrastructure as Code (IaC) patterns** — the kind of Terraform practices expected at high-performing platform engineering teams. Every file, module, and pipeline step was designed with an eye toward:

| Concern | How This Project Addresses It |
|---------|-------------------------------|
| **Reusability** | Modules are parameterized, versioned, and environment-agnostic. Dev and prod consume the same module code with different inputs. |
| **Composability** | Environments compose independent modules (VPC + EC2 + S3) rather than monolithic configurations. Swap, add, or remove modules without cross-contamination. |
| **Security by Default** | S3 buckets start encrypted, versioned, and publicly inaccessible. Security groups follow least-privilege. No opt-in required. |
| **Automated Governance** | CI enforces formatting, validation, linting, and security scanning on every push. Policy-as-code catches drift before it reaches production. |
| **Multi-Cloud Readiness** | Module structure and variable conventions are provider-agnostic. Adding GCP VPC or Azure VM modules is a directory creation away. |

### Who This Is For

- **DevOps / Platform Engineers** evaluating module design patterns
- **Terraform practitioners** looking for validated CI and security baselines
- **Interviewers and hiring managers** reviewing a structured IaC portfolio
- **Engineering teams** adopting reusable infrastructure modules

---

## Features

**Module Design**

- ✅ Three provider-independent module skeletons ready for AWS, GCP, Azure
- ✅ Typed, documented variables (`variables.tf`) with sensible defaults
- ✅ Explicit outputs (`outputs.tf`) for module composition
- ✅ Provider version pinning (`versions.tf`) for deterministic builds
- ✅ Consistent tagging strategy across all resources

**Environment Management**

- ✅ Directory-isolated environments (`dev/`, `prod/`) with independent state
- ✅ Environment-specific `terraform.tfvars` for scaling parameters
- ✅ Same module code, different configurations — zero duplication
- ✅ Clear composition layer showing how modules wire together

**CI/CD Pipeline**

- ✅ Terraform `fmt -check` for formatting consistency
- ✅ `terraform init` + `validate` for configuration correctness
- ✅ TFLint with AWS ruleset for code quality
- ✅ Checkov SAST scanning for security misconfigurations
- ✅ Graceful failure handling (`continue-on-error` on advisory checks)

**Security Hardening**

- ✅ S3 SSE-S256 encryption at rest (free, simple, effective)
- ✅ S3 versioning enabled for data recovery
- ✅ All four S3 public access blocks enforced
- ✅ SSH restricted to VPC-internal CIDR (`10.0.0.0/8`)
- ✅ Environment-based resource tagging for cost allocation

---

## Architecture

### Layer Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       GITHUB ACTIONS CI PIPELINE                         │
│  ┌──────────┐   ┌────────┐   ┌──────────┐   ┌────────┐   ┌──────────┐ │
│  │ fmt      │→  │ init   │→  │ validate │→  │ tflint │→  │ checkov  │ │
│  │ -check   │   │ -false │   │          │   │        │   │ (SAST)   │ │
│  └──────────┘   └────────┘   └──────────┘   └────────┘   └──────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        ENVIRONMENT LAYER                                 │
│  ┌─────────────────────────────┐    ┌────────────────────────────────┐ │
│  │  environments/dev/          │    │  environments/prod/            │ │
│  │  • main.tf (composition)    │    │  • main.tf (composition)      │ │
│  │  • terraform.tfvars (vars)  │    │  • terraform.tfvars (vars)    │ │
│  │  • dev.tfstate (local)      │    │  • prod.tfstate (local)       │ │
│  └──────────┬──────────────────┘    └────────────┬───────────────────┘ │
└─────────────┼────────────────────────────────────┼─────────────────────┘
              │              MODULE LAYER           │
┌─────────────┼────────────────────────────────────┼─────────────────────┐
│  ┌──────────▼──────────┐  ┌──────────▼──────────┐  ┌────────────────┐ │
│  │      VPC MODULE      │  │      EC2 MODULE      │  │   S3 MODULE     │ │
│  │                      │  │                      │  │                │ │
│  │  aws_vpc             │  │  aws_security_group   │  │  aws_s3_bucket │ │
│  │  aws_subnet (×2)     │  │  aws_instance (×N)   │  │  + versioning  │ │
│  │  aws_internet_gateway│  │  data.aws_ami         │  │  + encryption  │ │
│  │  aws_route_table     │  │  (Amazon Linux 2)     │  │  + public block│ │
│  │  + associations      │  │                      │  │                │ │
│  └──────────────────────┘  └──────────────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Author** pushes code or opens a PR to `main` touching `terraform/`
2. **GitHub Actions** triggers the CI pipeline: format check → init (no backend) → validate → lint (TFLint) → security scan (Checkov)
3. **Environment layer** reads `terraform.tfvars` and wires module calls in `main.tf`
4. **Module layer** receives typed variables, creates cloud resources, returns outputs
5. **Outputs** flow back to the environment composition for display or downstream consumption

### Key Design Principles

| Principle | Implementation |
|-----------|---------------|
| **Separation of Concerns** | Modules own resources; environments own composition and variables |
| **Don't Repeat Yourself** | One module definition shared across all environments |
| **Explicit over Implicit** | All variables have types, descriptions, and validation where applicable |
| **Fail Closed** | S3 buckets are private by default; SSH is restricted by default |
| **Observability** | Every resource tagged with `Environment` and `Name` for traceability |

---

## Quick Start

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) v1.9+
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials (or equivalent IAM role)

### Clone and Explore

```bash
git clone https://github.com/DynamicKarabo/multi-cloud-terraform.git
cd multi-cloud-terraform
```

### Initialize and Validate an Environment

```bash
# Work with the development environment
cd terraform/environments/dev

# Initialize (local backend — no cloud credentials needed for init)
terraform init

# Validate configuration and syntax
terraform validate

# See the execution plan (requires AWS credentials to refresh data sources)
terraform plan
```

### Apply (Requires AWS Credentials)

```bash
terraform apply
# Type 'yes' to confirm
```

> **⚠️ Note:** This project uses a **local backend** by default for zero-setup portfolio demonstration. For team collaboration, migrate to an S3 + DynamoDB backend as described in [State Management](#state-management).

### Explore the Module Documentation

Each module has a focused README and fully documented interface:

```bash
cat terraform/modules/README.md
# Or dive into a specific module:
head -20 terraform/modules/vpc/variables.tf
```

---

## Repository Structure

```
multi-cloud-terraform/
│
├── .github/
│   └── workflows/
│       └── terraform-ci.yml          # Multi-stage CI pipeline
│
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf               # Dev infrastructure composition
│   │   │   └── terraform.tfvars      # Dev-specific variable values
│   │   └── prod/
│   │       ├── main.tf               # Prod infrastructure composition
│   │       └── terraform.tfvars      # Prod-specific variable values
│   │
│   ├── modules/
│   │   ├── vpc/                      # Virtual Private Cloud
│   │   │   ├── main.tf               # Resource definitions
│   │   │   ├── variables.tf          # Typed input interface
│   │   │   ├── outputs.tf            # Exposed output values
│   │   │   └── versions.tf           # Provider constraints
│   │   │
│   │   ├── ec2/                      # Elastic Compute Cloud
│   │   │   ├── main.tf               # Resource definitions
│   │   │   ├── variables.tf          # Typed input interface
│   │   │   ├── outputs.tf            # Exposed output values
│   │   │   └── versions.tf           # Provider constraints
│   │   │
│   │   └── s3/                       # Simple Storage Service
│   │       ├── main.tf               # Resource definitions
│   │       ├── variables.tf          # Typed input interface
│   │       ├── outputs.tf            # Exposed output values
│   │       └── versions.tf           # Provider constraints
│   │
│   └── .tflint.hcl                   # TFLint configuration (AWS ruleset)
│
├── SYSTEM_DESIGN.md                  # Full system design document
├── DECISIONS.md                      # Architecture Decision Records
├── README.md                         # This file
└── .gitignore
```

---

## Module Deep Dive

### VPC Module

**Purpose:** Provision a fully-configured Virtual Private Cloud with public subnets, internet gateway, and routing.

**Source:** [`terraform/modules/vpc/`](terraform/modules/vpc/)

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `environment` | `string` | — (required) | Environment name for tagging |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | CIDR block for the VPC |

| Output | Type | Description |
|--------|------|-------------|
| `vpc_id` | `string` | ID of the provisioned VPC |
| `public_subnet_ids` | `list(string)` | IDs of the two public subnets |

**Key Design Decisions:**

- **Two subnets across two AZs** by default — provides AZ-level redundancy for high availability
- **DNS hostnames enabled** — required for EC2 instances to receive public DNS names
- **Subnet CIDRs auto-computed** via `cidrsubnet()` — no manual IP math needed
- **Internet Gateway attached** — allows public internet access from subnets
- **MapPublicIpOnLaunch=true** — instances in public subnets automatically receive public IPs

**Resources Created:**
- `aws_vpc` — Virtual Private Cloud
- `aws_subnet` — Two public subnets (AZ-aware)
- `aws_internet_gateway` — Internet gateway for public traffic
- `aws_route_table` — Public route table with default route to IGW
- `aws_route_table_association` — Association of each subnet to the route table

---

### EC2 Module

**Purpose:** Provision EC2 compute instances with a security group following least-privilege rules.

**Source:** [`terraform/modules/ec2/`](terraform/modules/ec2/)

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `environment` | `string` | — (required) | Environment name for tagging |
| `vpc_id` | `string` | — (required) | VPC ID for the security group |
| `subnet_id` | `string` | — (required) | Subnet ID for instance placement |
| `instance_type` | `string` | `"t3.micro"` | EC2 instance type |
| `instance_count` | `number` | `1` | Number of instances to provision |

| Output | Type | Description |
|--------|------|-------------|
| `instance_ids` | `list(string)` | IDs of provisioned instances |
| `instance_ips` | `list(string)` | Public IP addresses of instances |

**Key Design Decisions:**

- **Amazon Linux 2 AMI** — free tier eligible, AWS-optimized, SSM/CloudWatch agent pre-installed
- **AMI lookup via `data.aws_ami`** — always fetches latest AMI matching the filter; no hardcoded IDs
- **Security group with principle of least privilege:**
  - SSH (22): internal VPC CIDR only (`10.0.0.0/8`) — no public SSH
  - HTTP (80): open to internet
  - HTTPS (443): open to internet
  - Egress: full outbound access
- **Count-based scaling** — set `instance_count = 2` in prod for baseline HA
- **Public IP association** — instances get public IPs for web traffic

**Security Group Rules:**

| Direction | Protocol | Port | CIDR | Rationale |
|-----------|----------|------|------|-----------|
| Ingress | TCP | 22 | `10.0.0.0/8` | Internal SSH access only |
| Ingress | TCP | 80 | `0.0.0.0/0` | Public web traffic |
| Ingress | TCP | 443 | `0.0.0.0/0` | Public HTTPS traffic |
| Egress | All | All | `0.0.0.0/0` | Outbound connectivity |

---

### S3 Module

**Purpose:** Provision S3 buckets with enterprise security defaults: encryption, versioning, and public access blocked.

**Source:** [`terraform/modules/s3/`](terraform/modules/s3/)

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `environment` | `string` | — (required) | Environment name for tagging and bucket naming |
| `bucket_name` | `string` | — (required) | Base name for the bucket (appended with `-{environment}`) |

| Output | Type | Description |
|--------|------|-------------|
| `bucket_id` | `string` | ID of the created bucket |
| `bucket_arn` | `string` | ARN of the created bucket |

**Key Design Decisions:**

- **SSE-S3 (AES-256) encryption** — free, simple, meets most compliance baselines. KMS can be added as a variable without breaking changes.
- **Versioning enabled** — protects against accidental deletion and overwrites; enables point-in-time recovery
- **All four public access blocks enforced:**
  1. `block_public_acls` — blocks new public ACLs
  2. `block_public_policy` — blocks public bucket policies
  3. `ignore_public_acls` — ignores existing public ACLs
  4. `restrict_public_buckets` — denies access to buckets with public policies
- **Bucket name is environment-aware** — `demo-dev-data` + `-dev` suffix prevents cross-environment collision

**Security Baselines Applied:**

```hcl
# Encryption at rest — SSE-S3 (AES-256), zero cost, automatic
aws_s3_bucket_server_side_encryption_configuration

# Data protection — versioning for recovery and audit trails
aws_s3_bucket_versioning

# Access control — four-way public access block
aws_s3_bucket_public_access_block
```

---

## Environment Strategy

Environments are **directory-isolated** — each lives in its own `terraform/environments/<name>/` directory with independent state and variable files.

| Aspect | Dev (`environments/dev/`) | Prod (`environments/prod/`) |
|--------|---------------------------|------------------------------|
| **Region** | `us-east-1` (N. Virginia) | `us-west-2` (Oregon) |
| **Instance Type** | `t3.micro` | `t3.medium` |
| **Instance Count** | 1 | 2 |
| **S3 Bucket** | `demo-dev-data` | `demo-prod-data` |
| **VPC CIDR** | `10.0.0.0/16` | `10.0.0.0/16` |
| **State Backend** | Local (`dev.tfstate`) | Local (`prod.tfstate`) |

### Why Directory Isolation?

- **Complete separation** — no risk of dev configuration corrupting prod state
- **Independent validation** — CI validates dev only, but the pattern is identical for prod
- **Gradual rollout** — changes tested in dev first, then promoted to prod
- **No workspace complexity** — avoids Terraform workspace footguns with state isolation

### Adding a New Environment

```bash
# Copy the dev environment as a template
cp -r terraform/environments/dev terraform/environments/staging

# Customize variables
vim terraform/environments/staging/terraform.tfvars
# instance_type = "t3.small"
# instance_count = 1
# bucket_name   = "demo-staging-data"

# Validate independently
cd terraform/environments/staging
terraform init
terraform validate
```

---

## CI/CD Pipeline

Every push or pull request to `main` touching `terraform/` or `.github/workflows/` triggers the automated validation pipeline.

### Pipeline Stages

```
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌────────┐    ┌──────────┐
│  1. fmt  │───▶│ 2. init  │───▶│3.validate│───▶│4.tflint│───▶│5. checkov│
│  -check  │    │ -backend │    │          │    │        │    │ (SAST)   │
│          │    │ =false   │    │          │    │        │    │          │
│ ☑ Non-   │    │ ☑ Hard   │    │ ☑ Hard   │    │ ☑ Non- │    │ ☑ Non-   │
│   block  │    │   fail   │    │   fail   │    │   block│    │   block  │
└─────────┘    └──────────┘    └──────────┘    └────────┘    └──────────┘
```

| Stage | Tool | What It Checks | Failure Mode |
|-------|------|----------------|--------------|
| 1 | `terraform fmt -check` | HCL formatting consistency | Non-blocking (advisory) |
| 2 | `terraform init -backend=false` | Provider downloads, module resolution | Blocking |
| 3 | `terraform validate` | Configuration syntax, referential integrity | Blocking |
| 4 | `tflint --recursive` | Code quality, AWS best practices | Non-blocking (advisory) |
| 5 | `checkov --framework terraform` | Security misconfigurations, compliance | Non-blocking (advisory) |

### Design Rationale

- **`init -backend=false`** avoids needing actual cloud credentials in CI while still validating provider and module resolution
- **Non-blocking advisory stages** (`fmt`, `tflint`, `checkov`) surface issues without breaking CI — allows PR authors to see warnings while still getting a green check
- **Recursive tflint** catches issues across all modules and environments from a single invocation
- **Checkov SAST scanning** runs hundreds of built-in policies covering CIS benchmarks, HIPAA, PCI-DSS, and AWS Well-Architected

### GitHub Actions Workflow

The pipeline runs on `ubuntu-latest` with pinned tool versions:

- Terraform `1.9.0` (via `hashicorp/setup-terraform@v3`)
- TFLint `v0.52.0` (via `terraform-linters/setup-tflint@v4`)
- Checkov `action@v12` (via `bridgecrewio/checkov-action@v12`)

---

## Security &amp; Compliance

### Defense in Depth

This project applies multiple layers of security controls:

| Layer | Control | Module |
|-------|---------|--------|
| **Network** | SSH restricted to VPC-internal CIDR | EC2 |
| **Network** | No default public subnets (all subnets are intended for public resources) | VPC |
| **Storage** | SSE-S3 (AES-256) encryption at rest | S3 |
| **Storage** | Versioning enabled for data recovery | S3 |
| **Storage** | All four public access blocks active | S3 |
| **Identity** | Resource tagging for access control policies | All |
| **CI/CD** | Checkov SAST scanning on every commit | Pipeline |
| **CI/CD** | TFLint enforcement of AWS best practices | Pipeline |

### Tagging Strategy

Every resource carries two mandatory tags:

```hcl
tags = {
  Name        = "descriptive-resource-name"
  Environment = var.environment  # "dev" or "prod"
}
```

This enables:
- **Cost allocation** by environment in AWS Cost Explorer
- **Resource identification** across the AWS console and CLI
- **Automated cleanup** by environment tag
- **Policy enforcement** via IAM conditions on tags

### Security Baselines Checklist

- [x] S3 encryption at rest (AES-256)
- [x] S3 versioning for data protection
- [x] S3 public access blocked (all 4 blocks)
- [x] SSH restricted to internal CIDR
- [x] HTTP/HTTPS open for web traffic (intentional)
- [x] Security group egress unrestricted (default)
- [x] CI pipeline validates on every push
- [x] SAST scanning via Checkov
- [x] Linting via TFLint AWS ruleset
- [x] Consistent resource tagging

---

## State Management

### Current: Local Backend (Portfolio Mode)

```hcl
terraform {
  backend "local" {
    path = "dev.tfstate"
  }
}
```

Local state is appropriate for:
- **Portfolio demonstration** — zero setup, no cloud credentials needed to init
- **Local development** — fast iteration without state coordination
- **Interview walkthroughs** — fully self-contained repository

### Recommended: S3 + DynamoDB (Production Mode)

```hcl
terraform {
  backend "s3" {
    bucket         = "acme-terraform-state"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

| Feature | Local Backend | S3 + DynamoDB |
|---------|---------------|---------------|
| State storage | Local filesystem | S3 (durable, replicated) |
| State locking | None | DynamoDB (prevents concurrent operations) |
| Team collaboration | Single-user | Multi-user with locking |
| Encryption at rest | Filesystem-level | S3 SSE-S3/SSE-KMS |
| State versioning | Git (not recommended) | S3 versioning built-in |
| Disaster recovery | Manual backup | Automatic via S3 |

> **Migration path:** Create an S3 bucket and DynamoDB table (manually or via a bootstrap Terraform configuration), then update the `backend` block in each environment's `main.tf`. Run `terraform init -migrate` to copy existing state to the remote backend.

---

## Architecture Decisions

This project uses **Architecture Decision Records (ADRs)** — lightweight, timestamped documents that capture the context, decision, rationale, and consequences of every significant architectural choice.

| ADR | Decision | Status |
|-----|----------|--------|
| [ADR-001](DECISIONS.md#adr-001-aws-focus-over-multi-cloud) | AWS focus over multi-cloud | ✅ Accepted |
| [ADR-002](DECISIONS.md#adr-002-local-backend-over-remote-state) | Local backend over remote state | ✅ Accepted |
| [ADR-003](DECISIONS.md#adr-003-module-composition-over-monolithic-configurations) | Module composition over monolithic configs | ✅ Accepted |
| [ADR-004](DECISIONS.md#adr-004-checkov-over-tfsec) | Checkov over tfsec for SAST | ✅ Accepted |
| [ADR-005](DECISIONS.md#adr-005-amazon-linux-2-for-ec2-instances) | Amazon Linux 2 for EC2 instances | ✅ Accepted |
| [ADR-006](DECISIONS.md#adr-006-s3-encryption-and-public-access-blocked-by-default) | S3 encryption + public access blocked by default | ✅ Accepted |

> **Full document:** [`DECISIONS.md`](DECISIONS.md) — includes context, alternatives considered, and consequences for each decision.

### Sample ADR: Checkov over tfsec

> **Context:** We needed static analysis security scanning. Options were Checkov (Bridgecrew/Palo Alto) and tfsec (Aqua Security).
>
> **Decision:** Choose Checkov for broader AWS coverage, CIS benchmark policies, and native GitHub Actions integration.
>
> **Consequences:** More comprehensive security coverage at the cost of slightly slower execution vs. tfsec.

---

## Extending to GCP/Azure

The architecture is designed for multi-cloud extension. Here's how to add a new provider:

### Adding GCP Support

```
terraform/modules/
├── vpc/              # Existing AWS VPC module
├── ec2/              # Existing AWS EC2 module
├── s3/               # Existing AWS S3 module
├── gcp-vpc/          # New GCP VPC module
├── gcp-compute/      # New GCP Compute Engine module
└── gcp-storage/      # New GCP Cloud Storage module
```

Each GCP module follows the same conventions:
- `variables.tf` with typed inputs (same names as AWS where applicable)
- `outputs.tf` for composability
- `versions.tf` with `google` provider constraint
- Consistent tagging via `labels` (GCP equivalent of AWS tags)

### Multi-Provider Environment Composition

```hcl
# terraform/environments/dev/main.tf — extended example
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

module "aws_vpc" {
  source      = "../../modules/vpc"
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  providers = { aws = aws.us_east_1 }
}

module "gcp_vpc" {
  source      = "../../modules/gcp-vpc"
  environment = "dev"
  network_cidr = "10.1.0.0/16"
  providers = { google = google.us_central1 }
}
```

---

## Roadmap

- [ ] **GCP modules** — VPC, Compute Engine, Cloud Storage (following same patterns)
- [ ] **Azure modules** — VNet, Virtual Machines, Storage Account
- [ ] **Terratest integration tests** — automated validation of module behavior
- [ ] **`terraform-docs` integration** — auto-generated module documentation from variables/outputs
- [ ] **Pre-commit hooks** — fmt, validate, tflint, checkov running locally before push
- [ ] **`terraform apply` in CI** — with manual approval gates for production
- [ ] **KMS integration for S3** — variable toggle for SSE-KMS vs SSE-S3
- [ ] **Private subnets + NAT gateway** — for private instance deployments

---

## Contributing

Contributions are welcome! Here's how to get started:

1. **Fork** the repository
2. **Create a feature branch** (`git checkout -b feature/amazing-idea`)
3. **Make your changes** following existing patterns (typed variables, documented outputs, security defaults)
4. **Validate locally:**
   ```bash
   terraform fmt -check -recursive
   cd terraform/environments/dev && terraform init -backend=false && terraform validate
   tflint --recursive
   ```
5. **Commit** with a descriptive message
6. **Push** and open a Pull Request

### Guidelines

- Every new module needs `variables.tf`, `outputs.tf`, `versions.tf`, and `main.tf`
- Variables must have types and descriptions
- Resources must be tagged with `Environment` and `Name`
- Security-sensitive resources must default to the most restrictive setting
- New modules should be added to the module table in this README

---

## License

This project is licensed under the [MIT License](LICENSE). Use it freely as a reference, template, or starting point for your own infrastructure.

---

*Built with ❤️ as a DevOps portfolio case study. Demonstrating production-grade Terraform module design, CI/CD automation, and infrastructure security patterns.*
