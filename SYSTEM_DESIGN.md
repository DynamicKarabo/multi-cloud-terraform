# System Design: Multi-Cloud Terraform Modules

## 1. Goals

This project demonstrates production-grade Terraform module design and infrastructure-as-code patterns for a DevOps / Platform Engineering portfolio. The primary goals are:

- **Showcase modular Terraform composition** — Build reusable, composable infrastructure modules (VPC, EC2, S3) that can be mixed and matched across environments.
- **Demonstrate multi-environment patterns** — Maintain dev and prod environments with different scale parameters while reusing the same modules.
- **Validate with CI** — Automate formatting checks, validation, linting, and security scanning on every code change.
- **Enforce security by default** — Encrypt data at rest, block public access to storage, and follow least-privilege networking patterns.

## 2. Architecture

### Module Composition

```
┌──────────────────────────────────────────────────┐
│                  Environment                      │
│  (dev / prod)                                     │
│  ┌──────────┐  ┌──────────┐  ┌────────────────┐ │
│  │ VPC      │  │ EC2      │  │ S3             │ │
│  │ Module   │  │ Module   │  │ Module         │ │
│  │          │  │          │  │                │ │
│  │ • VPC    │  │ • SG     │  │ • Bucket       │ │
│  │ • 2× AZ  │  │ • AMI    │  │ • Versioning   │ │
│  │ • IGW    │  │ • Count  │  │ • Encryption   │ │
│  │ • Route  │  │          │  │ • Public Block │ │
│  └────┬─────┘  └────┬─────┘  └───────┬────────┘ │
│       │              │                │          │
│       └──────────────┴────────────────┘          │
│                     Outputs                       │
└──────────────────────────────────────────────────┘
```

### Data Flow

1. **Environment Layer** (`environments/dev/`, `environments/prod/`) defines variable values and module composition.
2. **Module Layer** (`modules/vpc/`, `modules/ec2/`, `modules/s3/`) encapsulates resource definitions and exposes typed inputs/outputs.
3. **CI Pipeline** validates the entire tree on every push/PR.

## 3. Environment Strategy

| Aspect | Dev | Prod |
|--------|-----|------|
| Region | us-east-1 | us-west-2 |
| Instance type | t3.micro | t3.medium |
| Instance count | 1 | 2 |
| S3 bucket | demo-dev-data | demo-prod-data |
| State backend | local (dev.tfstate) | local (prod.tfstate) |

Environments are isolated at the directory level. Each has its own `main.tf` that composes modules with environment-specific variables. This avoids cross-environment contamination and allows independent validation.

## 4. CI/CD Pipeline

```
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌────────┐    ┌────────┐
│  Push/PR │───▶│ fmt      │───▶│ init     │───▶│ validate│───▶│ tflint │
│  (main)  │    │ -check   │    │ -backend │    │         │    │        │
└─────────┘    └──────────┘    │ =false   │    └────────┘    └───┬────┘
                               └──────────┘                     │
                                                          ┌─────▼──────┐
                                                          │  Checkov   │
                                                          │  Security  │
                                                          │  Scan      │
                                                          └────────────┘
```

All steps run in GitHub Actions. `fmt` and `tflint` have `continue-on-error: true` to allow the pipeline to complete even with warnings.

## 5. Security

### Default-Secure S3 Configuration

- **Encryption**: AES-256 server-side encryption enforced via `aws_s3_bucket_server_side_encryption_configuration`
- **Versioning**: Enabled for data recovery and audit trails
- **Public Access**: All four public access blocks enabled (block public ACLs, block public policy, ignore public ACLs, restrict public buckets)

### EC2 Security Group Rules

- **SSH (22)**: Restricted to internal VPC CIDR (10.0.0.0/8) — no public SSH
- **HTTP (80)**: Open to internet (0.0.0.0/0) for web traffic
- **HTTPS (443)**: Open to internet (0.0.0.0/0) for secure web traffic
- **Egress**: Full outbound access allowed

### Resource Tagging

Every resource is tagged with `Environment` (dev/prod) and a descriptive `Name`. This enables:
- Cost allocation by environment
- Resource identification at a glance
- Automated cleanup by environment

## 6. State Management

### Current (Portfolio)

```hcl
terraform {
  backend "local" {
    path = "dev.tfstate"
  }
}
```

Local backend is used to avoid requiring real AWS credentials. State files stay on disk and are gitignored.

### Recommended (Production)

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Benefits of remote state:
- **Team collaboration**: Shared state file accessible by all team members
- **State locking**: DynamoDB prevents concurrent modifications
- **Encryption at rest**: S3 server-side encryption
- **Versioning**: State file history for rollback
- **Isolation**: Separate state keys per environment

## 7. Non-Goals

- **Actual cloud deployment**: This repository is designed for portfolio and interview demonstration. No real AWS infrastructure is provisioned.
- **GCP/Azure modules**: The architecture supports extension, but only AWS modules are implemented. This keeps the scope focused and maintainable.
- **CI apply step**: The pipeline validates but does not `terraform apply`. A real deployment pipeline would add an apply stage with manual approval for production.
- **Full test suite**: Terratest or other integration tests are not included, though the modular structure makes them straightforward to add.
