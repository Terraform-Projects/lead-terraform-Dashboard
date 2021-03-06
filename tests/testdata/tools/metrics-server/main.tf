provider "kubernetes" {
  config_path = var.kube_config_path
}

provider "helm" {
  version = "1.1.1"

  kubernetes {
    config_path = var.kube_config_path
  }
}

module "metrics_server" {
  source = "../../../../modules/tools/metrics-server"

  namespace = var.namespace
}
