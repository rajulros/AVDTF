
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

data "azurerm_virtual_network" "this" {
  name = local.virtual_network_name
  resource_group_name = data.azurerm_resource_group.vnet.name
}

data "azurerm_subnet" "image" {
  name                 = local.subnet_image_name
  resource_group_name  = data.azurerm_resource_group.vnet.name
  virtual_network_name = data.azurerm_virtual_network.this.name
}

// NSG creation 5
locals {
  nsg_names = [local.nsg_image_name]
  security_rule = {
    example_rule = {
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
    example_rule2 = {
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
    example_rule3 = {
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
    example_rule4 = {
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

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = {
    for idx, assoc in local.subnet_nsg_associations :
    idx => assoc
  }
  subnet_id                 = each.value.subnet_id
  network_security_group_id = each.value.nsg_id
}


data "azurerm_key_vault" "vault" {
  name                = local.keyvault_name_existing # Replace with your Key Vault name
  resource_group_name = data.azurerm_resource_group.shared.name                       # Replace with the resource group name where the Key Vault is deployed
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

data "azurerm_key_vault_secret" "sql_username" {
  name         = local.secretnamedsqlusername
  key_vault_id = data.azurerm_key_vault.vault.id
  #key_vault_id = "/subscriptions/8ac116fa-33ed-4b86-a94e-f39228fecb4a/resourceGroups/AD/providers/Microsoft.KeyVault/vaults/avd-domainjoin-for-lumen"
}

data "azurerm_key_vault_secret" "sql_password" {
  name         = local.secretnamedsqlpassword
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
data "azurerm_key_vault_secret" "adminpwd" {
  name         = local.secretnameadminpassword
  #key_vault_id = module.avm-res-keyvault-vault["resource_id"]
  key_vault_id = data.azurerm_key_vault.vault.id
}

# vm1 for AppV
locals {
  appv_vms = [
    {
      name = local.appv_vm1_name,
      sku_size = local.appv_vm1_sku_size,
      data_disks = local.appv_vm1_data_disk_size
    },
    {
      name = local.appv_vm2_name,
      sku_size = local.appv_vm2_sku_size,
      data_disks = local.appv_vm2_data_disk_size
    },
    {
      name = local.appv_vm3_name,
      sku_size = local.appv_vm3_sku_size,
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
    example_nic = {
      name = "${each.key}-nic"
      ip_configurations = {
        ipconfig1 = {
          name                          = "internal"
          private_ip_subnet_resource_id = data.azurerm_subnet.image.id
        }
      }
    }
  }

  zone                = "1"
  name                = each.value.name
  location            = var.location
  resource_group_name = local.resource_group_name_avd
  admin_username      = local.appvserveradminusername
  admin_password      = "${data.azurerm_key_vault_secret.adminpwd.value}"

  sku_size = each.value.sku_size

  # Image configuration
  source_image_reference = each.value.name == local.appv_vm1_name ? {
    offer     = local.appvdb_offer
    publisher = local.appvdb_offer
    sku       = local.appvdb_sku
    version   = local.appvdb_version
  } : {
    offer     = local.appv_offer
    publisher = local.appv_publisher
    sku       = local.appv_sku
    version   = local.appv_version
  }


  # Optional variables (add as needed)
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  data_disk_managed_disks = { for disk in each.value.data_disks : disk.name => {
    create_option        = "Empty"
    disk_size_gb         = disk.size_gb
    managed_disk_type    = disk.type
    storage_account_type = disk.type
    caching              = "ReadWrite"
    lun                  = disk.lun
    name                 = disk.name
  }}

  tags = {
    environment = "dev"
  }

  extensions = {
    "dj" = {
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
      count                       = contains([local.appv_vm2_name, local.appv_vm3_name], each.value.name) ? 1 : 0
      name                        = "InstallWebFeatures"
      publisher                   = "Microsoft.Compute"
      type                        = "CustomScriptExtension"
      type_handler_version        = "1.10"
      auto_upgrade_minor_version  = true
      automatic_upgrade_enabled   = false
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


resource "azurerm_mssql_virtual_machine" "mssql_vm" {
  count = local.appv_vm1_name == local.appv_vm1_name ? 1 : 0  # Replace this line

  virtual_machine_id               = module.appV[local.appv_vm1_name].resource_id  # Update here to use resource_id
  sql_license_type                 = "AHUB"
  r_services_enabled               = false
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_password = data.azurerm_key_vault_secret.sql_password.value
  sql_connectivity_update_username = data.azurerm_key_vault_secret.sql_username.value

  sql_instance {
      collation = "SQL_Latin1_General_CP1_CI_AS"
    }

  storage_configuration {
    disk_type = "NEW"
    storage_workload_type = "OLTP"

    data_settings {
      default_file_path = "F:\\data"
      luns      = [0]
    }
    log_settings {
      default_file_path = "G:\\log"
      luns      = [1]
    }
    temp_db_settings {
      default_file_path = "H:\\tempDb"
      data_file_count = 8
      data_file_size_mb = 8
      data_file_growth_in_mb = 64
      log_file_size_mb = 8
      log_file_growth_mb = 64
      luns      = [2]
    }

  }

  # auto_patching {
  #   day_of_week                            = "Sunday"
  #   maintenance_window_duration_in_minutes = 60
  #   maintenance_window_starting_hour       = 2
  # }
  depends_on = [ module.appV ]
}



