# Kubernetes Cluster with Red Hat Developer Hub

This Terraform configuration deploys a production-ready Kubernetes cluster on Civo with the following components:

- **Civo Kubernetes Cluster** (K3s) with Cilium CNI
- **Kgateway** (Gateway API implementation) for ingress
- **Red Hat Developer Hub** (optional) - Enterprise Backstage platform
- **Volume Snapshots** - Civo CSI driver with snapshot support
- **Firewall Rules** - Secure cluster and ingress access

## Prerequisites

Before you begin, ensure you have:

1. **Civo Account** - Sign up at [civo.com](https://civo.com) if you don't have one
2. **Red Hat Developer Account** (if using RHDH) - Sign up at [developers.redhat.com](https://developers.redhat.com)
3. **Terraform** - Install from [terraform.io](https://terraform.io)
4. **kubectl** - Install from [kubernetes.io](https://kubernetes.io/docs/tasks/tools/)
5. **helm** - Install from [helm.sh](https://helm.sh)

## Quick Start

### 1. Clone and Configure

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit Configuration

Edit `terraform.tfvars` with your settings:

```hcl
# Required: Your Civo API token
civo_token = "your-actual-civo-api-token"

# Cluster Configuration
cluster_node_size = "g4s.kube.small"  # or larger for production
region = "PHX1"  # or your preferred region
cluster_name_prefix = "my-cluster-"
cluster_node_count = 3

# Firewall Access (restrict as needed)
kubernetes_api_access = ["0.0.0.0/0"]
cluster_web_access = ["0.0.0.0/0"]
cluster_websecure_access = ["0.0.0.0/0"]

# Red Hat Developer Hub (optional)
enable_rhdh = true  # Set to false to skip RHDH
redhat_username = "your-redhat-username"
redhat_password = "your-redhat-password"
redhat_email = "your-redhat-email@example.com"
```

### 3. Get Your Civo API Token

1. Go to [civo.com/account/security](https://civo.com/account/security)
2. Generate a new API key
3. Copy the token to `terraform.tfvars`

### 4. Test Red Hat Credentials (if using RHDH)

```bash
# Test your Red Hat registry access
docker login registry.redhat.io
# Enter your username and password when prompted
```

### 5. Deploy the Cluster

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

The deployment takes approximately 10-15 minutes to complete.

## Accessing Your Cluster

### Setup kubectl Access

After successful deployment, configure kubectl access:

**Option 1: Use the generated kubeconfig directly**
```bash
kubectl --kubeconfig=./kubeconfig get nodes
```

**Option 2: Copy to your default kubectl config**
```bash
# Backup existing config (if you have one)
cp ~/.kube/config ~/.kube/config.backup

# Copy the new cluster config
cp ./kubeconfig ~/.kube/config

# Now you can use kubectl normally
kubectl get nodes
```

**Option 3: Export KUBECONFIG environment variable**
```bash
export KUBECONFIG=./kubeconfig
kubectl get nodes
```

**Option 4: Merge with existing kubectl configs**
```bash
# If you have multiple clusters, merge them
KUBECONFIG=~/.kube/config:./kubeconfig kubectl config view --flatten > ~/.kube/config.new
mv ~/.kube/config.new ~/.kube/config

# Switch to the new cluster context
kubectl config use-context tf-template-cluster
```

### Cluster Information

```bash
# Get cluster outputs
terraform output

# Examples:
terraform output cluster_api_endpoint
terraform output gateway_hostname
terraform output rhdh_url
```

## Red Hat Developer Hub Access

If you enabled RHDH, access it via:

1. **Get the URL:**
   ```bash
   terraform output rhdh_url
   ```

2. **Access via browser:**
   The URL will be something like: `http://your-gateway-hostname.lb.civo.com`

3. **First-time setup:**
   - RHDH will guide you through initial configuration
   - Configure your Git providers, authentication, etc.

## Components Deployed

### Core Infrastructure
- **3-node Kubernetes cluster** with Cilium CNI
- **Civo Volume Snapshots** for backup/restore
- **Firewall rules** for security

### Networking (Kgateway)
- **Gateway API CRDs** - Standard Kubernetes Gateway API
- **Kgateway Controller** - Gateway API implementation
- **Default Gateway** - HTTP/HTTPS ingress on port 80/443
- **Load Balancer** - Civo-managed external access

### Red Hat Developer Hub (Optional)
- **RHDH Application** - Enterprise Backstage platform
- **PostgreSQL Database** - Persistent storage for RHDH data
- **HTTPRoute** - Ingress routing via Gateway API
- **Pull Secrets** - Red Hat registry authentication

## Useful Commands

### Cluster Management
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check Gateway status
kubectl get gateway -n default
kubectl get httproute --all-namespaces

# Check RHDH status (if enabled)
kubectl get pods -n rhdh
kubectl logs -n rhdh -l app.kubernetes.io/name=developer-hub
```

### Troubleshooting
```bash
# Check events
kubectl get events --sort-by='.lastTimestamp' --all-namespaces

# Check specific component logs
kubectl logs -n kgateway-system -l app.kubernetes.io/name=kgateway
kubectl logs -n rhdh -l app.kubernetes.io/name=developer-hub

# Check persistent volumes
kubectl get pv,pvc --all-namespaces
```

## Configuration Options

### Cluster Sizing

Available node sizes (run `civo size list` for latest):
- `g4s.kube.small` - 1 vCPU, 2GB RAM (development)
- `g4s.kube.medium` - 2 vCPU, 4GB RAM (testing)
- `g4s.kube.large` - 4 vCPU, 8GB RAM (production)

### Regions

Available regions (run `civo region list` for latest):
- `NYC1` - New York
- `PHX1` - Phoenix
- `FRA1` - Frankfurt
- `LON1` - London

### Security

Restrict access by updating firewall rules in `terraform.tfvars`:
```hcl
# Example: Restrict API access to your IP
kubernetes_api_access = ["YOUR.IP.ADDRESS/32"]

# Example: Restrict web access to your office
cluster_web_access = ["OFFICE.IP.RANGE/24"]
```

## Cleanup

To destroy the cluster and all resources:

```bash
terraform destroy
```

**Warning:** This will permanently delete your cluster and all data.

## Support

- **Civo Documentation:** [civo.com/docs](https://civo.com/docs)
- **Red Hat Developer Hub:** [developers.redhat.com/rhdh](https://developers.redhat.com/rhdh)
- **Gateway API:** [gateway-api.sigs.k8s.io](https://gateway-api.sigs.k8s.io)
- **Terraform:** [terraform.io/docs](https://terraform.io/docs)

## Architecture

```
Internet
    ↓
Civo Load Balancer (Gateway)
    ↓
Kgateway (Gateway API)
    ↓
┌─────────────────────────────┐
│     Kubernetes Cluster     │
│  ┌─────────┐ ┌───────────┐ │
│  │  RHDH   │ │  Your     │ │
│  │ (Port   │ │  Apps     │ │
│  │  7007)  │ │           │ │
│  └─────────┘ └───────────┘ │
│                             │
│  ┌─────────────────────────┐ │
│  │     PostgreSQL DB       │ │
│  │   (Persistent Storage)  │ │
│  └─────────────────────────┘ │
└─────────────────────────────┘
```

This setup provides a production-ready foundation for your Kubernetes applications with enterprise-grade developer tools via Red Hat Developer Hub.