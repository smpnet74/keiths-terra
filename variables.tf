variable "civo_token" {
  description = "Civo API token"
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "FRA1"
  description = "The region to provision the cluster against"
}

variable "cluster_name_prefix" {
  description = "Prefix to append to the name of the cluster being created"
  type        = string
  default     = "tf-template-"
}

variable "cluster_node_size" {
  type        = string
  default     = "g4s.kube.medium"
  description = "The size of the nodes to provision. Run `civo size list` for all options"
}

variable "cluster_node_count" {
  description = "Number of nodes in the default pool"
  type        = number
  default     = 3
}

# Firewall Access
variable "kubernetes_api_access" {
  description = "List of Subnets allowed to access the Kube API"
  type        = list(any)
  default     = ["0.0.0.0/0"]
}

variable "cluster_web_access" {
  description = "List of Subnets allowed to access port 80 via the Load Balancer"
  type        = list(any)
  default     = ["0.0.0.0/0"]
}

variable "cluster_websecure_access" {
  description = "List of Subnets allowed to access port 443 via the Load Balancer"
  type        = list(any)
  default     = ["0.0.0.0/0"]
}

# RHDH Configuration
variable "rhdh_hostname" {
  description = "Custom hostname for RHDH. If not provided, will use gateway load balancer hostname"
  type        = string
  default     = ""
}

variable "rhdh_namespace" {
  description = "Namespace for Red Hat Developer Hub"
  type        = string
  default     = "rhdh"
}

variable "enable_rhdh" {
  description = "Whether to deploy Red Hat Developer Hub"
  type        = bool
  default     = false
}

variable "rhdh_use_https" {
  description = "Whether to use HTTPS for RHDH (requires TLS certificate)"
  type        = bool
  default     = false
}

# Red Hat Registry Authentication
variable "redhat_username" {
  description = "Red Hat registry username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "redhat_password" {
  description = "Red Hat registry password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "redhat_email" {
  description = "Red Hat registry email"
  type        = string
  default     = ""
}