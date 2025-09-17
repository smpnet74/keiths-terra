terraform {
  required_providers {
    #  User to provision resources (firewal / cluster) in civo.com
    civo = {
      source  = "civo/civo"
      version = "1.0.35"
    }

    # Used to output the kubeconfig to the local dir for local cluster access
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }

    # Used to provision helm charts into the k8s cluster
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }

    # Used to apply raw Kubernetes YAML, avoiding provider caching issues
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }

    # Used to manage time
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10.0"
    }

    # Used to generate random passwords
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }

    # Used for null resources and local-exec provisioners
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }

  }
}


# Configure the Civo Provider
provider "civo" {
  token  = var.civo_token
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(local_file.cluster-config.content)["clusters"][0]["cluster"]["server"]
    client_certificate     = base64decode(yamldecode(local_file.cluster-config.content)["users"][0]["user"]["client-certificate-data"])
    client_key             = base64decode(yamldecode(local_file.cluster-config.content)["users"][0]["user"]["client-key-data"])
    cluster_ca_certificate = base64decode(yamldecode(local_file.cluster-config.content)["clusters"][0]["cluster"]["certificate-authority-data"])
  }
}

provider "kubernetes" {
  host                   = yamldecode(local_file.cluster-config.content)["clusters"][0]["cluster"]["server"]
  client_certificate     = base64decode(yamldecode(local_file.cluster-config.content)["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(yamldecode(local_file.cluster-config.content)["users"][0]["user"]["client-key-data"])
  cluster_ca_certificate = base64decode(yamldecode(local_file.cluster-config.content)["clusters"][0]["cluster"]["certificate-authority-data"])
}

provider "kubectl" {
  host                   = yamldecode(local_file.cluster-config.content)["clusters"][0]["cluster"]["server"]
  cluster_ca_certificate = base64decode(yamldecode(local_file.cluster-config.content)["clusters"][0]["cluster"]["certificate-authority-data"])
  client_certificate     = base64decode(yamldecode(local_file.cluster-config.content)["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(yamldecode(local_file.cluster-config.content)["users"][0]["user"]["client-key-data"])
  load_config_file       = false
}