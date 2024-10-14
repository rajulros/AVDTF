terraform {
  backend "azurerm" {
    resource_group_name  = "Github"
    storage_account_name = "devopslumen01"
    container_name       = "tfstatefile"
    key                  = "terraform5.tfstate"

  }
}

