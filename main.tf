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

data "azurerm_subnet" "personal_hostpool" {
  name                 = local.subnet_personal_hostpool_name
  resource_group_name  = data.azurerm_resource_group.vnet.name
  virtual_network_name = data.azurerm_virtual_network.this.name
}

data "azurerm_subnet" "pooled_hostpool" {
  name                 = local.subnet_pooled_hootpool_name
  resource_group_name  = data.azurerm_resource_group.vnet.name
  virtual_network_name = data.azurerm_virtual_network.this.name
}

data "azurerm_subnet" "pe" {
  name                 = local.subnet_pe_name
  resource_group_name  = data.azurerm_resource_group.vnet.name
  virtual_network_name = data.azurerm_virtual_network.this.name
}

data "azurerm_subnet" "bastion" {
  name                 = local.subnet_bastion_name
  resource_group_name  = data.azurerm_resource_group.vnet.name
  virtual_network_name = data.azurerm_virtual_network.this.name
}

// DNS

data "azurerm_private_dns_zone" "example" {
  name                = "privatelink.bastion.azure.com"
  resource_group_name = local.dns_rg_name
}

data "azurerm_private_dns_zone" "example_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = local.dns_rg_name
}

data "azurerm_private_dns_zone" "example_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = local.dns_rg_name
}

data "azurerm_private_dns_zone" "example_keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.dns_rg_name
}

data "azurerm_private_dns_zone" "example_avd" {
  name                = "privatelink.wvd.microsoft.com"
  resource_group_name = local.dns_rg_name
}

// NSG creation 5
locals {
  nsg_names = [local.nsg_image_name, local.nsg_personal_hostpool_name, local.nsg_pooled_hostpool_name, local.nsg_pe_name]
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
    { subnet_id = data.azurerm_subnet.personal_hostpool.id, nsg_id = module.avm-res-network-networksecuritygroup[local.nsg_personal_hostpool_name].resource_id },
    { subnet_id = data.azurerm_subnet.pooled_hostpool.id, nsg_id = module.avm-res-network-networksecuritygroup[local.nsg_pooled_hostpool_name].resource_id },
    { subnet_id = data.azurerm_subnet.pe.id, nsg_id = module.avm-res-network-networksecuritygroup[local.nsg_pe_name].resource_id }
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


// HP

locals {
  hostpools = [
    {
      name = local.virtual_desktop_host_pool1_name,
      load_balancer_type = local.virtual_desktop_host_pool1_load_balancer_type,
      type = local.virtual_desktop_host_pool1_type,
      maximum_sessions_allowed = local.virtual_desktop_host_pool1_maximum_sessions_allowed,
      start_vm_on_connect = local.virtual_desktop_host_pool1_start_vm_on_connect,
      preferred_app_group_type = local.virtual_desktop_host_pool1_preferred_app_group_type
    },
    {
      name = local.virtual_desktop_host_pool2_name,
      load_balancer_type = local.virtual_desktop_host_pool2_load_balancer_type,
      type = local.virtual_desktop_host_pool2_type,
      maximum_sessions_allowed = local.virtual_desktop_host_pool2_maximum_sessions_allowed,
      start_vm_on_connect = local.virtual_desktop_host_pool2_start_vm_on_connect,
      preferred_app_group_type = local.virtual_desktop_host_pool2_preferred_app_group_type
    },
    {
      name = local.virtual_desktop_host_pool3_name,
      load_balancer_type = local.virtual_desktop_host_pool3_load_balancer_type,
      type = local.virtual_desktop_host_pool3_type,
      maximum_sessions_allowed = local.virtual_desktop_host_pool3_maximum_sessions_allowed,
      start_vm_on_connect = local.virtual_desktop_host_pool3_start_vm_on_connect,
      preferred_app_group_type = local.virtual_desktop_host_pool3_preferred_app_group_type
    },
    {
      name = local.virtual_desktop_host_pool4_name,
      load_balancer_type = local.virtual_desktop_host_pool4_load_balancer_type,
      type = local.virtual_desktop_host_pool4_type,
      maximum_sessions_allowed = local.virtual_desktop_host_pool4_maximum_sessions_allowed,
      start_vm_on_connect = local.virtual_desktop_host_pool4_start_vm_on_connect,
      preferred_app_group_type = local.virtual_desktop_host_pool4_preferred_app_group_type
    }
  ]
}

module "HP" {
  for_each                                            = { for hp in local.hostpools : hp.name => hp }
  source                                              = "Azure/avm-res-desktopvirtualization-hostpool/azurerm"
  version                                             = "0.2.1"
  resource_group_name                                 = data.azurerm_resource_group.avd.name
  virtual_desktop_host_pool_load_balancer_type        = each.value.load_balancer_type
  virtual_desktop_host_pool_location                  = var.location
  virtual_desktop_host_pool_name                      = each.value.name
  virtual_desktop_host_pool_resource_group_name       = data.azurerm_resource_group.avd.name
  virtual_desktop_host_pool_type                      = each.value.type
  virtual_desktop_host_pool_maximum_sessions_allowed  = each.value.maximum_sessions_allowed
  virtual_desktop_host_pool_start_vm_on_connect       = each.value.start_vm_on_connect
  virtual_desktop_host_pool_preferred_app_group_type  = each.value.preferred_app_group_type
  private_endpoints = {
    primary = {
      domain_name                     = local.domain_name_avd
      subnet_resource_id              = data.azurerm_subnet.pe.id
      private_dns_zone_group_name     = local.dns_rg_name
      private_dns_zone_resource_ids   = [data.azurerm_private_dns_zone.example_avd.id]
      private_service_connection_name = "hostpoolsc"
    }
  }
}

//Remote Apps
locals {
  remoteapp_groups = [
    { name = local.app1_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool1_name].resource.id, type = "RemoteApp" },
    { name = local.app2_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool1_name].resource.id, type = "RemoteApp" },
    { name = local.app3_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool1_name].resource.id, type = "RemoteApp"  },
    { name = local.app4_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool1_name].resource.id, type = "RemoteApp"  },
    { name = local.app5_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool1_name].resource.id, type = "RemoteApp"  },
    { name = local.app6_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool2_name].resource.id, type = "RemoteApp"  },
    { name = local.app7_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool2_name].resource.id, type = "RemoteApp"  },
    { name = local.app8_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool2_name].resource.id, type = "RemoteApp"  },
    { name = local.app9_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool2_name].resource.id, type = "RemoteApp"  },
    { name = local.app10_application_group_name, host_pool_id = module.HP[local.virtual_desktop_host_pool2_name].resource.id, type = "RemoteApp"  },
    { name = local.desktop_group1_name , host_pool_id = module.HP[local.virtual_desktop_host_pool3_name].resource.id, type = "Desktop"  },
    { name = local.desktop_group2_name , host_pool_id = module.HP[local.virtual_desktop_host_pool4_name].resource.id, type = "Desktop"  }
  ]
}

module "avm-res-remoteapp" {
  for_each                                             = { for group in local.remoteapp_groups : group.name => group }
  source                                                = "Azure/avm-res-desktopvirtualization-applicationgroup/azurerm"
  version                                               = "0.1.5"
  virtual_desktop_application_group_host_pool_id        = each.value.host_pool_id
  virtual_desktop_application_group_location            = var.location
  virtual_desktop_application_group_name                = each.value.name
  virtual_desktop_application_group_resource_group_name = data.azurerm_resource_group.avd.name
  virtual_desktop_application_group_type                = each.value.type
}

//Workspace
module "avm-res-desktopvirtualization-workspace" {
  source                                        = "Azure/avm-res-desktopvirtualization-workspace/azurerm"
  version                                       = "0.1.5"
  resource_group_name                           = local.resource_group_name_avd
  virtual_desktop_workspace_location            = var.location
  virtual_desktop_workspace_name                = local.virtual_desktop_workspace_name
  virtual_desktop_workspace_resource_group_name = data.azurerm_resource_group.avd.name
  subresource_names                             = ["feed"]
  private_endpoints = {
    primary = {
      domain_name        = local.domain_name_avd
      subnet_resource_id = data.azurerm_subnet.pe.id
      private_dns_zone_group_name = local.dns_rg_name,
      private_dns_zone_resource_ids = [data.azurerm_private_dns_zone.example_avd.id],
      private_service_connection_name = "workspacesc"
    }
  }
}

//Remote App Group WS Assignment
resource "azurerm_virtual_desktop_workspace_application_group_association" "example" {
  for_each = { for group in local.remoteapp_groups : group.name => group }
  workspace_id        = module.avm-res-desktopvirtualization-workspace.resource.id
  application_group_id = module.avm-res-remoteapp[each.key].resource.id
}

// keyvault
module "avm-res-keyvault-vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.9.1"
  # insert the 4 required variables here
  location            = var.location
  resource_group_name = data.azurerm_resource_group.avd.name
  name                = local.keyvault_name
  enable_telemetry    = true
  tenant_id           = var.tenant
  public_network_access_enabled = false
  legacy_access_policies_enabled = true
  legacy_access_policies = {
    test = {
      object_id               = var.object_id
      certificate_permissions = ["Get", "List"]
      key_permissions = ["Get", "Create"]
      secret_permissions = ["Set", "Get", "List", "Delete", "Purge", "Recover"]
    }
  }
  secrets = {
    test_secret = {
      name = "admin-password"
    }
  }
  secrets_value = {
    test_secret = random_password.admin_password.result
  }
  network_acls = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
  }
  private_endpoints = {
    primary = {
      subnet_resource_id = data.azurerm_subnet.pe.id
      object_id          = var.object_id
      tenant_id          = var.tenant
      private_dns_zone_group_name = local.dns_rg_name,
      private_dns_zone_resource_ids = [data.azurerm_private_dns_zone.example_keyvault.id],
      private_service_connection_name = "keyvaultsc"
    }
  }
}

// Diagnostics
module "avm-res-operationalinsights-workspace" {
  source              = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version             = "0.4.1"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.shared.name
  name                = local.operationalinsights_workspace_name
}





// Storage
locals {
  storage_accounts = [
    { name = local.diagstoragename },
    { name = local.fsstoragename },
    { name = local.artifactstoragename }
  ]
}

module "avm-res-storage-storageaccount" {
  for_each = { for sa in local.storage_accounts : sa.name => sa }
  source              = "Azure/avm-res-storage-storageaccount/azurerm"
  version             = "0.2.7"
  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.avd.name
  location            = var.location
  public_network_access_enabled = false
  allow_nested_items_to_be_public         = false
  shared_access_key_enabled = true
  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  private_endpoints = {
    storagepeblob = {
      name = "${each.value.name}blobpe"
      subnet_resource_id = data.azurerm_subnet.pe.id
      subresource_name = "blob"
      resource_group_name = local.resource_group_name_avd
      private_dns_zone_group_name = local.dns_rg_name
      private_dns_zone_resource_ids = [data.azurerm_private_dns_zone.example_blob.id]
      private_service_connection_name = "blobsc"
    },
    storagepefile = {
      name = "${each.value.name}filepe"
      subnet_resource_id = data.azurerm_subnet.pe.id
      subresource_name = "file"
      resource_group_name = local.resource_group_name_avd
      private_dns_zone_group_name = local.dns_rg_name
      private_dns_zone_resource_ids = [data.azurerm_private_dns_zone.example_file.id]
      private_service_connection_name = "filesc"
    }
  }
}

 resource "azurerm_storage_share" "example" {
    name                 = local.filesharename
    storage_account_name = local.fsstoragename
    quota                = 100
    depends_on = [module.avm-res-storage-storageaccount]
 }

# resource "azurerm_storage_share" "example" {
#   name                 = local.filesharename
#   storage_account_name = local.fsstoragename
#   quota                = 50
#   acl {
#     id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI"
#     access_policy {
#       permissions = "rwdl"
#       start       = "2019-07-02T09:38:21.0000000Z"
#       expiry      = "2019-07-02T10:38:21.0000000Z"
#     }
#   }
#   depends_on = [module.avm-res-storage-storageaccount]
# }






# // App Publishing
# resource "azurerm_virtual_desktop_application" "this" {
#   name                         = "test"
#   application_group_id         = module.remoteapp1.resource_id
#   friendly_name                = "test"
#   description                  = "test"
#   path                         = "C:\\Program Files\\MyApp\\myapp.exe"
#   icon_path                    = "C:\\Program Files\\MyApp\\myapp.exe"
#   command_line_argument_policy = "Allow"
# }




// Session Host VM
locals {
  vm_categories = [
    { name=local.sessionHost1_name, type="Pooled", subnet= data.azurerm_subnet.pooled_hostpool.id, category = local.virtual_desktop_host_pool1_name, image_sku = "win11-24h2-avd", count = 1, registration_info = module.HP[local.virtual_desktop_host_pool1_name].registrationinfo_token },
    { name=local.sessionHost2_name, type="Pooled", subnet= data.azurerm_subnet.pooled_hostpool.id, category = local.virtual_desktop_host_pool2_name, image_sku = "win11-24h2-avd", count = 1, registration_info = module.HP[local.virtual_desktop_host_pool2_name].registrationinfo_token },
    { name=local.sessionHost3_name, type="Personal", subnet= data.azurerm_subnet.personal_hostpool.id, category = local.virtual_desktop_host_pool3_name, image_sku = "win11-24h2-ent", count = 1, registration_info = module.HP[local.virtual_desktop_host_pool3_name].registrationinfo_token },
    { name=local.sessionHost4_name, type="Personal", subnet= data.azurerm_subnet.personal_hostpool.id, category = local.virtual_desktop_host_pool4_name, image_sku = "win11-24h2-ent", count = 1, registration_info = module.HP[local.virtual_desktop_host_pool4_name].registrationinfo_token },
  ]

  vm_instances = flatten([
    for vm in local.vm_categories : [
      for i in range(vm.count) : {
        type              = vm.type
        category          = vm.category
        image_sku         = vm.image_sku
        registration_info = vm.registration_info
        instance_index    = i
        subnet            = vm.subnet
        name              = "${vm.name}${i + 1}"
      }
    ]
  ])
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

resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "_%@"
  keepers = {
    constant = "same_password"
  }
}

data "azurerm_key_vault_secret" "adminpwd" {
  name         = "admin-password"
  key_vault_id = module.avm-res-keyvault-vault[local.keyvault_name].resource_id
  #key_vault_id = "/subscriptions/8ac116fa-33ed-4b86-a94e-f39228fecb4a/resourceGroups/AD/providers/Microsoft.KeyVault/vaults/avd-domainjoin-for-lumen"
}

// check the count
module "avm-res-compute-virtualmachine" {
  for_each = { for vm in local.vm_instances : "${vm.category}-${vm.type}-${vm.instance_index}" => vm }
  source   = "Azure/avm-res-compute-virtualmachine/azurerm"
  version  = "0.16.0"

  # Required variables
  network_interfaces = {
    example_nic = {
      name = "${each.key}-nic"
      ip_configurations = {
        ipconfig1 = {
          name                          = "internal"
          private_ip_subnet_resource_id = each.value.subnet
        }
      }
    }
  }
  zone = "1"
  name                = each.value.name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.avd.name
  admin_username      = local.adminuser
  admin_password      = "${data.azurerm_key_vault_secret.adminpwd.value}"

  # Image configuration
  source_image_reference = {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = each.value.image_sku
    version   = "latest"
  }

  # Optional variables (add as needed)
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Add a data disk of size Premium SSD ZRS 256GB
  data_disk_managed_disks = {
    example_data_disk = {
      create_option = "Empty"
      disk_size_gb  = 256
      managed_disk_type = "Premium_LRS"
      storage_account_type = "Premium_LRS"
      lun                     = 0
      caching                = "ReadWrite"
      name                    = "${each.value.name}-data-disk"
    }
  }

  extensions = {
    "dsc" = {
      name                       = "avd_dsc"
      publisher                  = "Microsoft.Powershell"
      type                       = "DSC"
      type_handler_version       = "2.73"
      auto_upgrade_minor_version = true
      settings = <<-SETTINGS
      {
        "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip",
        "configurationFunction": "Configuration.ps1\\AddSessionHost",
        "properties": {
          "HostPoolName":"${each.value.category}"
        }
      }
      SETTINGS

      protected_settings = <<-PROTECTED_SETTINGS
      {
        "properties": {
          "registrationInfoToken": "${each.value.registration_info}"
        }
      }
      PROTECTED_SETTINGS
    },
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
  }
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
          private_ip_subnet_resource_id = data.azurerm_subnet.personal_hostpool.id
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
  source_image_reference = {
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
  }
}

# Azure Bastion
module "avm-res-network-publicipaddress" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.1.2"
  # insert the 3 required variables here
  location            = var.location
  resource_group_name = data.azurerm_resource_group.avd.name
  name                = "avd-bastion-pip"
  allocation_method   = "Static"
  sku                 = "Standard"
}

# module "azure_bastion" {
#   source = "Azure/avm-res-network-bastionhost/azurerm"
#   version = "0.3.0"
#   enable_telemetry    = true
#   resource_group_name = data.azurerm_resource_group.avd.name
#   location = var.location
#   name = "avd-bastion"
#   copy_paste_enabled     = true
#   file_copy_enabled      = false
#   sku                 = "Standard"  # Change to Premium SKU
#   ip_configuration = {
#     name                 = "my-ipconfig"
#     subnet_id            = data.azurerm_subnet.bastion.id
#     public_ip_address_id = module.avm-res-network-publicipaddress.public_ip_id  # Set to null to use private IP
#   }
#   ip_connect_enabled     = true
#   scale_units            = 4
#   shareable_link_enabled = true
#   tunneling_enabled      = true
#   kerberos_enabled       = true
 
#   tags = {
#     environment = "dev"
#   }
# }

#Azure Recovery Services Vault
resource "azurerm_recovery_services_vault" "rsv" {
  name                = local.recovery_vault_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.avd.name
  sku                 = "Standard"

  soft_delete_enabled = true
}