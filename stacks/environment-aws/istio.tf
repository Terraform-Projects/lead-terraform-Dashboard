data "helm_repository" "istio" {
  name     = "istio.io"
  url      = "https://storage.googleapis.com/istio-release/releases/1.4.2/charts/"
  provider = helm.system
}

resource "helm_release" "istio_init" {
  count      = var.enable_istio ? 1 : 0
  repository = data.helm_repository.istio.metadata[0].name
  chart      = "istio-init"
  namespace  = module.infrastructure.namespace
  name       = "istio-init"
  timeout    = 600
  wait       = true
  provider   = helm.system
  version    = "1.4.2"
}

# Give the CRD a chance to settle
resource "null_resource" "istio_init_delay" {
  provisioner "local-exec" {
    command = "sleep 15"
  }
  depends_on = [helm_release.istio_init]
}

module "istio_system" {
  source                  = "../../modules/common/istio"
  enabled                 = var.enable_istio
  namespace               = "istio-system"
  crd_waiter              = null_resource.istio_init_delay.id
  cluster_domain          = "${var.cluster}.${var.root_zone_name}"
  toolchain_namespace     = module.toolchain.namespace
  issuer_name             = module.staging_cluster_issuer.issuer_name
  issuer_kind             = module.staging_cluster_issuer.issuer_kind

  providers = {
    helm = helm.system
  }
  flagger_event_webhook = "${module.sdm.slack_operator_in_cluster_url}/canary-events"
}
