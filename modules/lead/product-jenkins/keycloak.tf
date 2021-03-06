
data "kubernetes_secret" "keycloak_credentials" {
  provider = kubernetes.toolchain

  metadata {
    name      = "keycloak-credentials"
    namespace = "toolchain"
  }
}

data "kubernetes_secret" "keycloak_toolchain_realm" {
  provider = kubernetes.toolchain

  metadata {
    name      = "keycloak-toolchain-realm"
    namespace = "toolchain"
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  // trick provider into not caring if username/password don't exist
  username      = var.enable_keycloak ? data.kubernetes_secret.keycloak_credentials.data.admin_username : "username"
  password      = var.enable_keycloak ? data.kubernetes_secret.keycloak_credentials.data.admin_password : "password"
  url           = "${local.protocol}://keycloak.toolchain.${var.cluster_domain}"
  initial_login = false
}

resource "keycloak_openid_client" "jenkins_openid_client" {
  count                 = var.enable_keycloak ? 1 : 0
  realm_id              = data.kubernetes_secret.keycloak_toolchain_realm.data.id
  client_id             = "${module.toolchain_namespace.name}.jenkins.${var.cluster_domain}"
  name                  = "Jenkins - ${title(module.toolchain_namespace.name)}"
  access_type           = "PUBLIC"
  standard_flow_enabled = true
  valid_redirect_uris = [
    "http://localhost:8080/securityRealm/finishLogin",                                                               # for local environment port forwarding
    "${local.protocol}://${module.toolchain_namespace.name}.jenkins.${var.cluster_domain}/securityRealm/finishLogin" # for dns routable or via ingress
  ]
}

resource "keycloak_openid_user_property_protocol_mapper" "jenkins_openid_user_property_mapper_email" {
  count     = var.enable_keycloak ? 1 : 0
  realm_id  = data.kubernetes_secret.keycloak_toolchain_realm.data.id
  client_id = keycloak_openid_client.jenkins_openid_client[0].id
  name      = "email"

  user_property = "email"
  claim_name    = "email"
}
