# Architecture Decision Records

## ADR-001: AWS Focus Over Multi-Cloud

**Status**: Accepted  
**Date**: 2026-05-07

### Context

The repository is named "multi-cloud-terraform" but needs to decide which cloud providers to implement first.

### Decision

Implement only AWS modules initially. The module architecture (separate directories per provider, consistent variable/output patterns) supports future GCP and Azure additions without rework.

### Rationale

- AWS dominates the US fintech market where this portfolio is targeted
- Deepening AWS expertise is more valuable than shallow multi-cloud coverage
- AWS has the richest Terraform provider ecosystem for demonstration

### Consequences

- Positive: Focused, production-quality AWS modules
- Positive: Clean extension points for GCP/Azure
- Negative: "Multi-cloud" name implies broader coverage than currently exists

---

## ADR-002: Local Backend Over Remote State

**Status**: Accepted  
**Date**: 2026-05-07

### Context

Terraform state must be stored somewhere. Options: local filesystem, S3 backend, Terraform Cloud, or HashiCorp Consul.

### Decision

Use local backend for this repository, with documented migration path to S3 + DynamoDB.

### Rationale

- No real AWS infrastructure is deployed — local state is simpler and has no credential requirements
- Eliminates the bootstrap problem of creating the state bucket with Terraform itself
- Keeps the repository self-contained for interview walkthroughs
- Remote state adds complexity without benefit for a portfolio-only project

### Consequences

- Positive: Zero setup friction for reviewers and interviewers
- Positive: State files stay gitignored and local
- Negative: Not suitable for team collaboration without migration
- Mitigation: README includes ready-to-use S3 backend configuration

---

## ADR-003: Module Composition Over Monolithic Configurations

**Status**: Accepted  
**Date**: 2026-05-07

### Context

Terraform configurations can be organized as large monolithic files or broken into reusable modules.

### Decision

Decompose infrastructure into three focused modules (VPC, EC2, S3) composed at the environment level.

### Rationale

- Modules can be versioned, tested, and documented independently
- Environment configurations become declarative compositions of modules
- Follows HashiCorp's recommended patterns and AWS Well-Architected Framework
- Easier to review and maintain than single large configurations

### Consequences

- Positive: Reusable across environments (dev/prod share the same module code)
- Positive: Each module has a single responsibility
- Negative: More files to manage, but this is standard Terraform practice

---

## ADR-004: Checkov Over tfsec

**Status**: Accepted  
**Date**: 2026-05-07

### Context

We need static analysis security scanning for Terraform configurations. Two leading options: Checkov (by Bridgecrew/Palo Alto) and tfsec (by Aqua Security).

### Decision

Use Checkov for security scanning in the CI pipeline.

### Rationale

- Checkov has broader coverage for AWS resources and Terraform patterns
- Checkov includes built-in policies for CIS benchmarks, HIPAA, and PCI-DSS
- Active development and community support
- GitHub Actions integration is straightforward via `bridgecrewio/checkov-action`

### Consequences

- Positive: Comprehensive security coverage out of the box
- Positive: Well-documented ignore/suppression patterns
- Negative: Slightly slower than tfsec for large configurations
- Negative: tfsec has better output formatting for some use cases

---

## ADR-005: Amazon Linux 2 for EC2 Instances

**Status**: Accepted  
**Date**: 2026-05-07

### Context

EC2 instances need an Amazon Machine Image (AMI). Options include Amazon Linux 2, Amazon Linux 2023, Ubuntu, Red Hat, and others.

### Decision

Use Amazon Linux 2 (amzn2-ami-hvm-*-x86_64-gp2) as the default AMI.

### Rationale

- Free tier eligible and widely used in AWS environments
- Well-integrated with AWS services (SSM Agent, CloudWatch Agent pre-installed)
- Stable and well-documented for Terraform demonstrations
- Consistent with environments where this portfolio is targeted (fintech)

### Consequences

- Positive: Known behavior and wide support
- Positive: No licensing costs
- Negative: Amazon Linux 2023 is the current generation — migration may be needed
- Mitigation: AMI is fetched dynamically via `data.aws_ami` so changing the filter updates all instances

---

## ADR-006: S3 Encryption and Public Access Blocked by Default

**Status**: Accepted  
**Date**: 2026-05-07

### Context

S3 buckets should follow security best practices by default. Two key decisions: encryption method and public access configuration.

### Decision

- Enforce AES-256 server-side encryption (SSE-S3) by default
- Block all public access via `aws_s3_bucket_public_access_block`
- Enable versioning for data protection

### Rationale

- SSE-S3 is free, simple, and meets compliance requirements for many workloads
- Public access blocks prevent accidental data exposure — a leading cause of AWS breaches
- Versioning provides protection against accidental deletion and overwrites
- These three settings together form a minimal "secure by default" S3 baseline

### Consequences

- Positive: Buckets are secure out of the box with zero configuration
- Positive: Versioning enables point-in-time recovery
- Negative: SSE-S3 uses AWS-managed keys (not KMS) — some compliance frameworks require KMS
- Mitigation: Architecture supports adding KMS without breaking changes
