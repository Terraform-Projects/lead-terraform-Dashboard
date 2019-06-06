data "template_file" "artifactory_security_values" {
  template = "${file("${path.module}/artifactory.security.import.xml")}"
}

data "template_file" "artifactory_config_values" {
  template = "${file("${path.module}/artifactory.config.import.xml")}"
  // vars = {
  //   namespace        = "${var.namespace}"
  //   logstash_url     = "http://lead-dashboard-logstash.${var.namespace}.svc.cluster.local:9000"
  // }
}

resource "kubernetes_config_map" "artifactory_config" {
  metadata {
    name = "lead-bootstrap-artifactory-config"
  }

  data {
    artifactory.config.import.xml = "${data.template_file.artifactory_config_values.rendered}"
  }

  data {
    security.import.xml = "${data.template_file.artifactory_security_values.rendered}"
  }
}



resource "random_string" "artifactory_admin_password" {
  length  = 10
  special = false
}

resource "random_string" "artifactory_db_password" {
  length  = 10
  special = false
 }

data "helm_repository" "jfrog" {
  name = "jfrog"
  url  = "https://charts.jfrog.io"
}

resource "helm_release" "artifactory" {
  depends_on = ["kubernetes_config_map.artifactory_config"]
  repository = "jfrog"
  name       = "artifactory"
  namespace  = "${module.toolchain_namespace.name}"
  chart      = "artifactory"
  version    = "7.14.3"
  timeout    = 1200


  #values = ["${data.template_file.artifactory_values.rendered}"]
  set {
    name  = "artifactory.configMapName"
    value = "lead-bootstrap-artifactory-config"
  }

  set {
    name  = "nginx.enabled"
    value = "false"
  }

  set_sensitive {
    name  = "artifactory.license.licenseKey"
    value = "${var.artifactory_license}"
  }

  set_sensitive {
     name  = "postgresql.postgresPassword"
     value = "${random_string.artifactory_db_password.result}"
   }

  set_sensitive {
   name  = "artifactory.accessAdmin.password"
   value = "${random_string.artifactory_admin_password.result}"
  }
}
