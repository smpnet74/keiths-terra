# Data sources for dynamic resource discovery
# Gateway-related data sources moved to gateway_infrastructure.tf

# Application-specific computed values
locals {
  # Determine the hostname to use for RHDH
  # Reference gateway hostname from gateway_infrastructure.tf
  rhdh_hostname = var.rhdh_hostname != "" ? var.rhdh_hostname : local.gateway_hostname

  # Base URL for RHDH - configurable protocol
  rhdh_base_url = "${var.rhdh_use_https ? "https" : "http"}://${local.rhdh_hostname}"
}