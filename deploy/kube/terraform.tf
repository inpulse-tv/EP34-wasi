terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  backend "local" {
    path = "./state/terraform.tfstate"
  }
  required_version = ">= 0.13"
}
