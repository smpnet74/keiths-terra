# Create a firewall
resource "civo_firewall" "firewall" {
  name                 = "${var.cluster_name_prefix}firewall-new"
  create_default_rules = false

  ingress_rule {
    protocol   = "tcp"
    port_range = "6443"
    cidr       = var.kubernetes_api_access
    label      = "kubernetes-api-server"
    action     = "allow"
  }
}

# Create a firewall for ingress
resource "civo_firewall" "firewall-ingress" {
  name                 = "${var.cluster_name_prefix}firewall-ingress"
  create_default_rules = false

  ingress_rule {
    protocol   = "tcp"
    port_range = "80"
    cidr       = var.cluster_web_access
    label      = "web"
    action     = "allow"
  }

  ingress_rule {
    protocol   = "tcp"
    port_range = "443"
    cidr       = var.cluster_websecure_access
    label      = "websecure"
    action     = "allow"
  }
}

# Add a wait before firewall destruction to ensure proper cleanup
resource "time_sleep" "wait_for_firewall" {
  depends_on       = [civo_firewall.firewall]
  destroy_duration = "240s"
}