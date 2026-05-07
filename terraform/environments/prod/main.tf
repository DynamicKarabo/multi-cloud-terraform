terraform {
  backend "local" {
    path = "prod.tfstate"
  }
}

module "vpc" {
  source      = "../../modules/vpc"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"
}

module "ec2" {
  source         = "../../modules/ec2"
  environment    = "prod"
  vpc_id         = module.vpc.vpc_id
  subnet_id      = module.vpc.public_subnet_ids[0]
  instance_type  = "t3.medium"
  instance_count = 2
}

module "s3" {
  source      = "../../modules/s3"
  environment = "prod"
  bucket_name = "demo-prod-data"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "instance_ips" {
  value = module.ec2.instance_ips
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}
