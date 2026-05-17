terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "vdcd-rg-tfstate-ause"
    storage_account_name = "vdcdtfstateause"
    container_name       = "tfstate"
    key                  = "app-service.tfstate"
  }
}

provider "azurerm" {
  features {}
}
