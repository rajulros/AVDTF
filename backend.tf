terraform {
  backend "azurerm" {
    resource_group_name  = "AVDDevOps"
    storage_account_name = "avddevopsautomation"
    container_name       = "tfstate"
    key                  = "terraform6.tfstate"

  }
}

