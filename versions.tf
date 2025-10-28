terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.0.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
  required_version = ">= 1.2.5"
}