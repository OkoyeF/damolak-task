terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "damolak-task"
    key          = "damolak-task/dev/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  ecr_image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-2.amazonaws.com/damolak-task:dev"
}

module "networking" {
  source               = "../modules/networking"
  environment          = "dev"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}

module "ecs" {
  source            = "../modules/ecs"
  environment       = "dev"
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  ecr_image_uri     = local.ecr_image_uri
  app_port          = 5000
  desired_count     = 1
}

module "monitoring" {
  source       = "../modules/monitoring"
  environment  = "dev"
  cluster_name = module.ecs.cluster_name
  service_name = module.ecs.service_name
}
