# Gateway API and Kgateway Implementation

# Install Gateway API CRDs separately
resource "null_resource" "gateway_api_crds" {
  provisioner "local-exec" {
    command = <<-EOT
      # Install Gateway API CRDs v1.2.1 (as per official docs)
      kubectl --kubeconfig ${path.module}/kubeconfig apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
    EOT
  }

  depends_on = [
    time_sleep.wait_for_cluster,
    null_resource.cilium_upgrade  # Ensure Cilium is installed first
  ]
}

# Wait for Gateway API CRDs to be established
resource "time_sleep" "wait_for_gateway_crds" {
  depends_on = [null_resource.gateway_api_crds]
  create_duration = "30s"
}

# Install Kgateway CRDs using Helm (as per official docs)
resource "helm_release" "kgateway_crds" {
  name             = "kgateway-crds"
  repository       = "" # Using OCI registry instead of traditional Helm repo
  chart            = "oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds"
  version          = "v2.0.3"  # Stable version
  namespace        = "kgateway-system"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true

  depends_on = [
    null_resource.gateway_api_crds,
    time_sleep.wait_for_gateway_crds
  ]
}

# Wait for Kgateway CRDs to be established
resource "time_sleep" "wait_for_kgateway_crds" {
  depends_on = [helm_release.kgateway_crds]
  create_duration = "30s"
}

# Install Kgateway using Helm
resource "helm_release" "kgateway" {
  name             = "kgateway"
  repository       = "" # Using OCI registry instead of traditional Helm repo
  chart            = "oci://cr.kgateway.dev/kgateway-dev/charts/kgateway"
  version          = "v2.0.3"  # Stable version
  namespace        = "kgateway-system"
  create_namespace = true
  atomic           = false  # Set to false to prevent rollback on timeout
  cleanup_on_fail  = true
  wait             = true
  timeout          = 900    # 15 minutes

  # Configure namespace discovery to include default namespace
  # This is critical for Kgateway to discover Gateway resources
  values = [
    yamlencode({
      discoveryNamespaceSelectors = [
        # Include default namespace where Gateway will be located
        {
          matchLabels = {
            "kubernetes.io/metadata.name" = "default"
          }
        },
        # Include kgateway-system namespace
        {
          matchLabels = {
            "kubernetes.io/metadata.name" = "kgateway-system"
          }
        },
        # Also include any namespace with gateway-related labels
        {
          matchLabels = {
            "gateway.networking.k8s.io/managed-by" = "kgateway"
          }
        }
      ]
      # Add resource requests for Gateway proxy pods
      gatewayProxies = {
        default = {
          podTemplate = {
            proxyContainer = {
              resources = {
                requests = {
                  cpu    = "100m"
                  memory = "128Mi"
                }
                limits = {
                  cpu    = "500m"
                  memory = "512Mi"
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [
    helm_release.kgateway_crds,
    time_sleep.wait_for_kgateway_crds
  ]
}

# Create a Gateway resource with both HTTP and HTTPS support
resource "kubectl_manifest" "default_gateway" {
  yaml_body = <<-YAML
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: default-gateway
  namespace: default
  labels:
    workload-type: temporary
spec:
  gatewayClassName: kgateway
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
  - name: https
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: default-gateway-tls
        kind: Secret
    allowedRoutes:
      namespaces:
        from: All
  YAML

  depends_on = [
    helm_release.kgateway
  ]
}

# Create a self-signed TLS certificate for the Gateway
resource "kubectl_manifest" "gateway_tls_certificate" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: default-gateway-tls
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: ${base64encode(tls_self_signed_cert.gateway_cert.cert_pem)}
  tls.key: ${base64encode(tls_private_key.gateway_key.private_key_pem)}
  YAML

  depends_on = [
    tls_self_signed_cert.gateway_cert
  ]
}

# Generate private key for TLS certificate
resource "tls_private_key" "gateway_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate self-signed certificate
resource "tls_self_signed_cert" "gateway_cert" {
  private_key_pem = tls_private_key.gateway_key.private_key_pem

  subject {
    common_name  = "*.lb.civo.com"
    organization = "RHDH Development"
  }

  dns_names = [
    "*.lb.civo.com",
    "localhost"
  ]

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}