# Gateway Infrastructure - Single source of truth for gateway data discovery
# This file owns all gateway-related data sources and timing controls

# Wait for gateway service to be fully ready with LoadBalancer IP
# Consolidated from duplicate definitions in data.tf and cloudflare_dns.tf
resource "time_sleep" "wait_for_gateway_lb" {
  depends_on      = [kubectl_manifest.default_gateway]
  create_duration = "120s" # Use longer duration for reliability (from cloudflare_dns.tf)
}

# Get gateway load balancer service to extract hostname/IP
# Single authoritative data source for gateway service information
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

# Gateway-specific computed values
locals {
  # Extract gateway IP/hostname with fallback logic
  gateway_lb_ip = try(
    data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].ip,
    try(data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].hostname, "")
  )

  # Extract gateway hostname for application use
  gateway_hostname = try(
    data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].hostname,
    "localhost"
  )

  # Validate that we have a valid IP address
  has_valid_gateway_ip = length(local.gateway_lb_ip) > 0 && local.gateway_lb_ip != "192.0.2.1"
}