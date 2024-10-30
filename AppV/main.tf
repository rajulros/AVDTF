// RG
data "azurerm_resource_group" "vnet" {
  name = local.resource_group_name_vnet
}

data "azurerm_resource_group" "avd" {
  name = local.resource_group_name_avd
}

data "azurerm_resource_group" "shared" {
  name = local.resource_group_name_shared
}

// VNET

data "azurerm_virtual_network" "virtualnet" {
  name                = local.virtual_network_name
  resource_group_name = data.azurerm_resource_group.vnet.name
}

data "azurerm_subnet" "image" {
  name                 = local.subnet_image_name
  resource_group_name  = data.azurerm_resource_group.vnet.name
  virtual_network_name = data.azurerm_virtual_network.virtualnet.name
}

data "azurerm_key_vault" "vault" {
  name                = local.keyvault_name_existing            # Replace with your Key Vault name
  resource_group_name = data.azurerm_resource_group.shared.name # Replace with the resource group name where the Key Vault is deployed
}

# Retrieve the domain join username from Azure Key Vault
data "azurerm_key_vault_secret" "domain_username" {
  name         = local.secretnamedjusername
  key_vault_id = data.azurerm_key_vault.vault.id
  #key_vault_id = "/subscriptions/8ac116fa-33ed-4b86-a94e-f39228fecb4a/resourceGroups/AD/providers/Microsoft.KeyVault/vaults/avd-domainjoin-for-lumen"
}
# Retrieve the domain join password from Azure Key Vault
data "azurerm_key_vault_secret" "domain_password" {
  name         = local.secretnamedjpassword
  key_vault_id = data.azurerm_key_vault.vault.id
  #key_vault_id = "/subscriptions/8ac116fa-33ed-4b86-a94e-f39228fecb4a/resourceGroups/AD/providers/Microsoft.KeyVault/vaults/avd-domainjoin-for-lumen"
}

resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "_%@"
  keepers = {
    constant = "same_password"
  }
}

data "azurerm_key_vault_secret" "appvadminpwd" {
  name = local.secretnameappvadminpassword
  #key_vault_id = module.avm-res-keyvault-vault["resource_id"]
  key_vault_id = data.azurerm_key_vault.vault.id
}
locals {
  nsg_names = [local.nsg_image_name]
  security_rule = {
    rule01 = {
      name                       = "SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    rule02 = {
      name                       = "RDP"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    rule03 = {
      name                       = "HTTP"
      priority                   = 1003
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    rule04 = {
      name                       = "HTTPS"
      priority                   = 1004
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}
#tfsec:ignore:azure-network-no-public-ingress tfsec:ignore:azure-network-disable-rdp-from-internet tfsec:ignore:azure-network-ssh-blocked-from-internet
module "avm-res-network-networksecuritygroup" {
  for_each = toset(local.nsg_names)
  source   = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version  = "0.2.0"

  location            = var.location
  name                = each.value
  resource_group_name = data.azurerm_resource_group.avd.name
  security_rules      = local.security_rule
}

// NSG Subnet Association
locals {
  subnet_nsg_associations = [
    { subnet_id = data.azurerm_subnet.image.id, nsg_id = module.avm-res-network-networksecuritygroup[local.nsg_image_name].resource_id },
  ]
}

resource "azurerm_subnet_network_security_group_association" "nsgassociation" {
  for_each = {
    for idx, assoc in local.subnet_nsg_associations :
    idx => assoc
  }
  subnet_id                 = each.value.subnet_id
  network_security_group_id = each.value.nsg_id
}

# vm1 for AppV
locals {
  appv_vms = [
    {
      name       = local.appv_vm1_name,
      sku_size   = local.appv_vm1_sku_size,
      data_disks = local.appv_vm1_data_disk_size
    },
    {
      name       = local.appv_vm2_name,
      sku_size   = local.appv_vm2_sku_size,
      data_disks = local.appv_vm2_data_disk_size
    },
    {
      name       = local.appv_vm3_name,
      sku_size   = local.appv_vm3_sku_size,
      data_disks = local.appv_vm3_data_disk_size
    }
  ]
}

module "appV" {
  for_each = { for vm in local.appv_vms : vm.name => vm }
  source   = "Azure/avm-res-compute-virtualmachine/azurerm"
  version  = "0.16.0"

  # Required variables
  network_interfaces = {
    vm_nic = {
      name = "${each.key}-nic"
      ip_configurations = {
        ipconfig1 = {
          name                 = "${each.key}-internal"
          private_ip_subnet_id = data.azurerm_subnet.image.id
        }
      }
    }
  }

  zone                = "1"
  name                = each.value.name
  location            = var.location
  resource_group_name = local.resource_group_name_avd
  admin_username      = local.appvserveradminusername
  admin_password      = data.azurerm_key_vault_secret.appvadminpwd.value

  sku_size = each.value.sku_size

  # Image configuration
  source_image_reference = {
    offer     = local.appv_offer
    publisher = local.appv_publisher
    sku       = local.appv_sku
    version   = local.appv_version
  }

  # Optional variables (add as needed)
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  data_disk_managed_disks = { for disk in each.value.data_disks : disk.name => {
    create_option        = "Empty"
    disk_size_gb         = disk.size_gb
    managed_disk_type    = disk.type
    storage_account_type = disk.type
    caching              = "ReadWrite"
    lun                  = disk.lun
    name                 = disk.name
  } }

  tags = {
    environment = "dev"
  }

  extensions = {
    "domain_join" = {
      name                       = "domainjoin"
      publisher                  = "Microsoft.Compute"
      type                       = "JsonADDomainExtension"
      type_handler_version       = "1.3"
      auto_upgrade_minor_version = true

      settings = <<-SETTINGS
        {
          "Name": "${local.domainname}",
          "OUPath": "${local.oupath}",
          "User": "${data.azurerm_key_vault_secret.domain_username.value}",
          "Restart": "true",
          "Options": "3"
        }
        SETTINGS

      protected_settings = <<-PSETTINGS
        {
          "Password": "${data.azurerm_key_vault_secret.domain_password.value}"
        }
        PSETTINGS
    }
     "install_web_features" = {
      name                        = "InstallWebFeatures"
      publisher                   = "Microsoft.Compute"
      type                        = "CustomScriptExtension"
      type_handler_version        = "1.10"
      auto_upgrade_minor_version  = true
      automatic_upgrade_enabled   = true
      failure_suppression_enabled = true
      settings                    = <<SETTINGS
         {      
          "commandToExecute" : "powershell.exe -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-App-Dev, Web-Net-Ext, Web-Net-Ext45, Web-Asp-Net, Web-Asp-Net45, Web-ISAPI-Filter, Web-ISAPI-Ext, Web-Security, Web-Windows-Auth\""
         }
        SETTINGS

      provision_after_extensions = []
      # settings                   = {}
      # tags                       = {}
    }
  }
  }
