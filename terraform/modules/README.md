# Terraform Modules

## Available Modules

| Module | Description | Inputs | Outputs |
|--------|-------------|--------|---------|
| vpc | VPC with public subnets, IGW, routing | environment, vpc_cidr | vpc_id, public_subnet_ids |
| ec2 | EC2 instances with security group | environment, vpc_id, subnet_id, instance_type, instance_count | instance_ips, instance_ids |
| s3 | S3 bucket with encryption and versioning | environment, bucket_name | bucket_id, bucket_arn |

## Usage

```hcl
module "vpc" {
  source      = "../../modules/vpc"
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
}
```

## Best Practices

- Every module has explicit variables.tf with types and descriptions
- Every output is documented
- versions.tf pins provider versions
- Resources tagged with environment for cost tracking
- S3 buckets enforce encryption and block public access by default
