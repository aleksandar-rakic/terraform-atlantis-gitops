terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state-staging"
    key            = "staging/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  env         = "staging"
  common_tags = {
    Environment = local.env
    Project     = var.project_name
    ManagedBy   = "terraform"
    Repository  = "aleksandar-rakic/terraform-atlantis-gitops"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name               = "${var.project_name}-${local.env}"
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  tags               = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  identifier        = "${var.project_name}-${local.env}"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  engine_version    = "16.3"
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  subnet_ids        = module.vpc.private_subnet_ids
  vpc_id            = module.vpc.vpc_id
  tags              = local.common_tags
}
