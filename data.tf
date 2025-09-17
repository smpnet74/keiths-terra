# Data sources for dynamic resource discovery

# Wait for gateway service to be fully ready with LoadBalancer IP
resource "time_sleep" "wait_for_gateway_lb" {
  depends_on = [kubectl_manifest.default_gateway]
  create_duration = "60s"  # Wait for LoadBalancer to be provisioned
}

# Get gateway load balancer service to extract hostname/IP
# This always runs to ensure gateway info is available
data "kubernetes_service" "gateway_lb" {
  metadata {
    name      = "default-gateway"
    namespace = "default"
  }

  depends_on = [
    kubectl_manifest.default_gateway,
    time_sleep.wait_for_gateway_lb
  ]
}

# Local values for computed configuration
locals {
  # Determine the hostname to use for RHDH
  # Always use the gateway hostname if available, fall back to localhost only if gateway doesn't exist
  rhdh_hostname = var.rhdh_hostname != "" ? var.rhdh_hostname : (
    try(data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].hostname, "localhost")
  )

  # Base URL for RHDH - configurable protocol
  rhdh_base_url = "${var.rhdh_use_https ? "https" : "http"}://${local.rhdh_hostname}"
}