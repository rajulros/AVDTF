output "database_vm_id" {
  value = module.appV[local.appv_vm1_name].resource_id  # This should work after making the above changes
}
