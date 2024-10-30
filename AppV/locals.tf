locals {
    adminuser = "adminuser"
    appvserveradminusername = "appvserveruser"
    domainname = "Manageddevices.in"
    oupath = "OU=WESTUS3,OU=WIN11,OU=Pooled,OU=SessionHost,OU=AVD,DC=Manageddevices,DC=in"
    domainusername = "svcavddj@manageddevices.in"
    virtualmachinename = "vdvmlumen"
    virtual_network_name = "AVD-TF-VNET"
    subnet_image_name         = "vd-snet-image-n-mgmt-avd-poc-cus-01"
    

    resource_group_name_vnet = "RG-AVD-TF-WUS3"
    resource_group_name_shared = "RG-AVD-TF-WUS3"
    resource_group_name_avd = "RG-AVD-TF-WUS3"
    resource_group_name_dns = "RG-AVD-TF-WUS3"

    nsg_image_name = "vd-nsg-image-avd-poc-cus-01"
    
    avd_rg_name = "RG-AVD-TF-WUS3"
    avd_rg_shared_name = "RG-AVD-TF-WUS3"

    // DNS RG Name
    dns_rg_name = "RG-AVD-TF-WUS3"

    // Existing Keyvault
    keyvault_name_existing = "kvavd008"
    secretnamedjusername = "AVDDJUN"
    secretnamedjpassword = "AVDDJPW"
    secretnameadminpassword = "admin-password"

    // storage
    storage_account_name = "vdavdstorageaccount1"
    storageblobpename = "vdavdstorageblobpe"
    storagefilepename = "vdavdstoragefilepe"
    diagstoragename = "vddiagstoragename1"
    fsstoragename = "vdfsstoragename1"
    artifactstoragename = "vdartifactstoragename1"
    filesharename = "vdlumenfilesharename1"

    // AppV  3 VM Names
    appv_vm1_name = "appv-vm1"
    appv_vm2_name = "appv-vm2"
    appv_vm3_name = "appv-vm3"

    // sku size of 3 Vms
    # appv_vm1_sku_size = "Standard_D8lds_v5" # 8 vCPUs
    # appv_vm2_sku_size = "Standard_D8ls_v5"  # 8 vCPUs
    # appv_vm3_sku_size = "Standard_D8ls_v5"  # 8 vCPUs

    appv_vm1_sku_size = "Standard_D2s_v5" # 2 vCPUs
    appv_vm2_sku_size = "Standard_D2s_v5" # 2 vCPUs
    appv_vm3_sku_size = "Standard_D2s_v5" # 2 vCPUs

    // AppV  3 VM data disk sizes
    appv_vm1_data_disk_size = [
      { size_gb = 100, type = "Premium_LRS", name = "appv-vm1-disk1", lun = 0 },
      { size_gb = 100, type = "Premium_LRS", name = "appv-vm1-disk2", lun = 1 },
      { size_gb = 50, type = "Premium_LRS", name = "appv-vm1-disk3", lun = 2 },
      { size_gb = 50, type = "Premium_LRS", name = "appv-vm1-disk4", lun = 3 }
      ]
    appv_vm2_data_disk_size = [
      { size_gb = 1024, type = "Premium_LRS", name = "appv-vm2-disk1", lun = 0 }
      ]
    appv_vm3_data_disk_size = [
      { size_gb = 1024, type = "Premium_LRS", name = "appv-vm3-disk1", lun = 0 }
      ]

    // AppV image Sku
    appv_sku = "2022-datacenter"
    appv_offer = "WindowsServer"
    appv_publisher = "MicrosoftWindowsServer"
    appv_version = "latest"

    // key Vault name
    keyvault_name = "kvlumenavd007"


    }