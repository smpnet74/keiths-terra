# Cloudflare DNS Management
# Depends on gateway_infrastructure.tf for gateway data

resource "cloudflare_dns_record" "root" {
  zone_id    = var.cloudflare_zone_id
  name       = var.domain_name
  content    = local.gateway_lb_ip # Reference from gateway_infrastructure.tf
  type       = "A"
  proxied    = true                             # Enable Cloudflare proxying
  ttl        = 1                                # Automatic
  depends_on = [time_sleep.wait_for_gateway_lb] # Reference from gateway_infrastructure.tf

  lifecycle {
    precondition {
      condition     = local.has_valid_gateway_ip # Reference from gateway_infrastructure.tf
      error_message = "Gateway load balancer IP address is not available yet. Please run terraform apply again after the load balancer IP is assigned."
    }
  }
}

resource "cloudflare_dns_record" "wildcard" {
  zone_id    = var.cloudflare_zone_id
  name       = "*"
  content    = local.gateway_lb_ip              # Reference from gateway_infrastructure.tf
  type       = "A"                              # Change to A record
  proxied    = true                             # Enable Cloudflare proxying
  ttl        = 1                                # Automatic
  depends_on = [time_sleep.wait_for_gateway_lb] # Reference from gateway_infrastructure.tf

  lifecycle {
    precondition {
      condition     = local.has_valid_gateway_ip # Reference from gateway_infrastructure.tf
      error_message = "Gateway load balancer IP address is not available yet. Please run terraform apply again after the load balancer IP is assigned."
    }
  }
}