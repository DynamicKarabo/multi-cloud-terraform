# Multi-Cloud Terraform

![Terraform CI](https://github.com/DynamicKarabo/multi-cloud-terraform/actions/workflows/terraform-ci.yml/badge.svg)

Reusable Terraform modules for provisioning cloud infrastructure, with validated CI pipelines, remote state patterns, and multi-environment configurations. Currently focused on **AWS** with a modular architecture designed for extension to GCP and Azure.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     terraform/environments/                  │
│  ┌─────────────────────┐    ┌─────────────────────────────┐ │
│  │         dev          │    │           prod               │ │
│  │  region: us-east-1   │    │  region: us-west-2           │ │
│  │  t3.micro × 1        │    │  t3.medium × 2              │ │
│  │  demo-dev-data       │    │  demo-prod-data             │ │
│  └────────┬────────────┘    └──────────┬──────────────────┘ │
└───────────┼─────────────────────────────┼───────────────────┘
            │                             │
┌───────────┼─────────────────────────────┼───────────────────┐
│           │     terraform/modules/       │                   │
│  ┌────────▼────────┐  ┌────────▼────────┐  ┌──────────────┐ │
│  │       VPC        │  │       EC2        │  │      S3       │ │
│  │ • Public subnets │  │ • Security group │  │ • Encryption  │ │
│  │ • IGW + routing  │  │ • Amazon Linux 2 │  │ • Versioning  │ │
│  │ • AZ-aware       │  │ • Count-based    │  │ • Public      │ │
│  │                  │  │                  │  │   block       │ │
│  └─────────────────┘  └──────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Clone the repository
git clone https://github.com/DynamicKarabo/multi-cloud-terraform.git
cd multi-cloud-terraform

# Navigate to an environment
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview resources
terraform plan

# Apply (requires AWS credentials)
terraform apply
```

> **Note:** This repo uses a local backend by default. For production use, migrate to an S3 backend with DynamoDB locking (see [Remote State](#remote-state)).

## Repository Structure

```
multi-cloud-terraform/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml       # CI pipeline: fmt, validate, tflint, checkov
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf            # Dev environment composition
│   │   │   └── terraform.tfvars   # Dev-specific variables
│   │   └── prod/
│   │       ├── main.tf            # Prod environment composition
│   │       └── terraform.tfvars   # Prod-specific variables
│   ├── modules/
│   │   ├── vpc/                   # VPC module (subnets, IGW, routing)
│   │   ├── ec2/                   # EC2 module (instances, security groups)
│   │   └── s3/                    # S3 module (encryption, versioning, access blocks)
│   │   └── README.md              # Module usage guide
│   └── .tflint.hcl                # TFLint configuration
├── SYSTEM_DESIGN.md               # System design document
├── DECISIONS.md                   # Architecture Decision Records
└── README.md                      # This file
```

## Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| [vpc](terraform/modules/vpc) | Virtual Private Cloud | Public subnets across AZs, IGW, route tables |
| [ec2](terraform/modules/ec2) | Compute instances | Security group, Amazon Linux 2, auto-scaling via count |
| [s3](terraform/modules/s3) | Object storage | SSE-S256 encryption, versioning, public access blocked |

## Environments

| Environment | Region | Instance Type | Instance Count | S3 Bucket |
|-------------|--------|---------------|----------------|-----------|
| **dev** | us-east-1 | t3.micro | 1 | demo-dev-data |
| **prod** | us-west-2 | t3.medium | 2 | demo-prod-data |

## CI/CD Pipeline

Every push or PR to `main` that touches `terraform/` triggers:

1. **Terraform fmt** — Checks formatting (non-blocking)
2. **Terraform init** — Initializes dev environment
3. **Terraform validate** — Validates configuration
4. **TFLint** — Linting with AWS ruleset (non-blocking)
5. **Checkov** — Security scanning (SAST)

## Security Practices

- **S3**: Server-side encryption (AES-256) enabled by default, versioning enabled, all public access blocked
- **EC2**: Security groups restrict SSH to internal CIDR (10.0.0.0/8), HTTP/HTTPS open to internet
- **Tagging**: All resources tagged with `Environment` for cost allocation and resource management
- **IAM**: Follow least-privilege — modules assume an appropriate IAM role is assigned at the environment level

## Remote State

This project uses a **local backend** for simplicity and portfolio demonstration. For production deployments, use an S3 backend with DynamoDB locking:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

This pattern enables state isolation per environment, state locking for concurrent operations, and encrypted storage of sensitive state data.

## License

MIT
