terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.0" # Adjust the version as needed
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.1, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
    # azapi = {
    #   source  = "Azure/azapi"
    #   version = ">= 1.4.0, < 2.0" #"~> 1.13"
    # }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}