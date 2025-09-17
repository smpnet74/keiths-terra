# Terraform outputs for cluster information

# Cluster outputs
output "cluster_id" {
  description = "Civo Kubernetes cluster ID"
  value       = civo_kubernetes_cluster.cluster.id
}

output "cluster_name" {
  description = "Civo Kubernetes cluster name"
  value       = civo_kubernetes_cluster.cluster.name
}

output "cluster_api_endpoint" {
  description = "Kubernetes API endpoint"
  value       = civo_kubernetes_cluster.cluster.api_endpoint
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = local_file.cluster-config.filename
}

# Gateway outputs
output "gateway_hostname" {
  description = "Gateway load balancer hostname"
  value       = try(data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].hostname, "Gateway not deployed")
}

output "gateway_ip" {
  description = "Gateway load balancer IP"
  value       = try(data.kubernetes_service.gateway_lb.status[0].load_balancer[0].ingress[0].ip, "Gateway not deployed")
}

# RHDH outputs
output "rhdh_url" {
  description = "Red Hat Developer Hub URL"
  value       = var.enable_rhdh ? local.rhdh_base_url : "RHDH not enabled"
  depends_on  = [data.kubernetes_service.gateway_lb]
}

output "rhdh_namespace" {
  description = "Red Hat Developer Hub namespace"
  value       = var.enable_rhdh ? var.rhdh_namespace : "RHDH not enabled"
}