terraform {
  backend "s3" {}
}

provider "kubernetes" {
  alias            = "staging"
  load_config_file = var.load_config_file
  config_context   = var.config_context
}

provider "aws" {
  version = ">= 2.29.0"
  region  = var.region

  skip_metadata_api_check = true
}

provider "helm" {
  alias   = "staging"
  version = "1.1.1"

  kubernetes {
    load_config_file = var.load_config_file
    config_context   = var.config_context
  }
}

provider "kubernetes" {
  alias            = "production"
  load_config_file = var.load_config_file
  config_context   = var.config_context
}

provider "helm" {
  alias   = "production"
  version = "1.1.1"

  kubernetes {
    load_config_file = var.load_config_file
    config_context   = var.config_context
  }
}

module "product-aws" {
  source                      = "../../modules/lead/product-aws"
  cluster_domain              = var.cluster_domain
  cluster                     = var.cluster
  product_name                = var.product_name
  image_whitelist             = var.image_whitelist
  region                      = var.region
  pipelines                   = var.pipelines
  codebuild_role              = var.codebuild_role
  codepipeline_role           = var.codepipeline_role
  s3_bucket                   = var.s3_bucket
  codebuild_user              = var.codebuild_user
  source_type                 = var.source_type
  aws_environment             = var.aws_environment
  codebuild_security_group_id = var.codebuild_security_group_id
  toolchain_image_repo        = var.toolchain_image_repo
  product_image_repo          = var.product_image_repo
  builder_images_version      = var.builder_images_version

  providers = {
    kubernetes.staging    = kubernetes.staging
    helm.staging          = helm.staging
    kubernetes.production = kubernetes.production
    helm.production       = helm.production
    aws                   = aws
  }
}
