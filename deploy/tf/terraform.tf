terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "local" {
    path = "./state/terraform.tfstate"
  }
  required_version = ">= 0.13"
}
