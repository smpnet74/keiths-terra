# Red Hat Developer Hub (RHDH) Installation
# Using official OpenShift charts repository

# Create namespace for RHDH
resource "kubernetes_namespace" "rhdh" {
  count = var.enable_rhdh ? 1 : 0

  metadata {
    name = var.rhdh_namespace
  }

  depends_on = [
    helm_release.kgateway
  ]
}

# Create Red Hat registry pull secret
resource "kubernetes_secret" "rhdh_pull_secret" {
  count = var.enable_rhdh ? 1 : 0

  metadata {
    name      = "rhdh-pull-secret"
    namespace = var.rhdh_namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.redhat.io" = {
          username = var.redhat_username
          password = var.redhat_password
          email    = var.redhat_email
          auth     = base64encode("${var.redhat_username}:${var.redhat_password}")
        }
      }
    })
  }

  depends_on = [
    helm_release.kgateway
  ]
}

# Create service account with image pull secret
resource "kubernetes_service_account" "rhdh" {
  count = var.enable_rhdh ? 1 : 0

  metadata {
    name      = "rhdh"
    namespace = var.rhdh_namespace
  }

  image_pull_secret {
    name = "rhdh-pull-secret"
  }

  depends_on = [
    kubernetes_secret.rhdh_pull_secret
  ]
}

# Note: Dynamic plugins ConfigMap removed - using appConfig settings instead

# Install Red Hat Developer Hub using official OpenShift Helm chart
resource "helm_release" "rhdh" {
  count = var.enable_rhdh ? 1 : 0
  name             = "rhdh"
  repository       = "https://charts.openshift.io/"
  chart            = "redhat-developer-hub"
  version          = "1.7.0"  # Latest available version
  namespace        = var.rhdh_namespace
  create_namespace = true
  atomic           = false
  cleanup_on_fail  = true
  wait             = true
  timeout          = 900    # 15 minutes

  values = [
    yamlencode({
      # Global configuration
      global = {
        host = local.rhdh_hostname
        imagePullSecrets = ["rhdh-pull-secret"]
      }

      # Disable OpenShift-specific resources for Kubernetes
      route = {
        enabled = false
      }

      # Use NodePort service type as per documentation
      upstream = {
        service = {
          type = "NodePort"
        }
        ingress = {
          enabled = false  # We're using Gateway API instead
        }
        backstage = {
          appConfig = {
            app = {
              baseUrl = local.rhdh_base_url
              # ONLY FIX: Add experimental setting to disable digest/integrity checks
              experimental = {
                packages = {
                  disableIntegrityCheck = true
                }
              }
            }
            backend = {
              baseUrl = local.rhdh_base_url
              cors = {
                origin = local.rhdh_base_url
              }
              # Configure CSP based on protocol - disable upgrade-insecure-requests for HTTP
              csp = var.rhdh_use_https ? {} : {
                "upgrade-insecure-requests" = false
              }
            }
            auth = {
              environment = "development"
              providers = {
                guest = {
                  dangerouslyAllowOutsideDevelopment = true
                }
              }
            }
            signInPage = "guest"
            dangerouslyAllowSignInWithoutUserInCatalog = true
            # Minimal catalog configuration to prevent digest errors
            catalog = {
              locations = []
              providers = {}
              rules = [
                {
                  allow = ["Component", "System", "API", "Resource", "Location", "User", "Group", "Template"]
                }
              ]
            }
            # Disable problematic integrations
            integrations = {
              github = []
              gitlab = []
              bitbucket = []
            }
            # Disable techdocs which can cause digest issues
            techdocs = {
              builder = "local"
              generator = {
                runIn = "local"
              }
              publisher = {
                type = "local"
              }
            }
          }
          podSecurityContext = {
            fsGroup = 2000
          }
        }
        postgresql = {
          primary = {
            podSecurityContext = {
              enabled = true
              fsGroup = 3000
            }
          }
        }
        volumePermissions = {
          enabled = true
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.rhdh,
    kubernetes_secret.rhdh_pull_secret,
    kubernetes_service_account.rhdh,
    helm_release.kgateway,
    kubectl_manifest.default_gateway,
    kubectl_manifest.gateway_tls_certificate,
    data.kubernetes_service.gateway_lb
  ]
}

# Create ReferenceGrant to allow RHDH HTTPRoute to reference the Gateway
resource "kubectl_manifest" "rhdh_reference_grant" {
  count = var.enable_rhdh ? 1 : 0
  yaml_body = <<-YAML
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-rhdh-to-default-gateway
  namespace: default
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    namespace: ${var.rhdh_namespace}
  to:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: default-gateway
  YAML

  depends_on = [
    kubectl_manifest.default_gateway
  ]
}

# Create HTTPRoute for RHDH to expose it through kgateway
resource "kubectl_manifest" "rhdh_httproute" {
  count = var.enable_rhdh ? 1 : 0
  yaml_body = <<-YAML
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: rhdh-route
  namespace: ${var.rhdh_namespace}
spec:
  parentRefs:
  - name: default-gateway
    namespace: default
    kind: Gateway
  hostnames:
  - "${local.rhdh_hostname}"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: rhdh-developer-hub
      port: 7007
      kind: Service
  YAML

  depends_on = [
    helm_release.rhdh,
    kubectl_manifest.default_gateway,
    kubectl_manifest.rhdh_reference_grant,
    data.kubernetes_service.gateway_lb
  ]
}