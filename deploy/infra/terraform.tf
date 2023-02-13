terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "local" {
    path = "./state/terraform.tfstate"
  }
  required_version = ">= 0.13"

}
