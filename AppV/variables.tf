variable "object_id" {
  type = string
  description = "the object ID " 
}

variable "tenant" {
  type        = string
  description = "The tenant ID to use for the Key Vault."
  nullable    = false
}

variable "location" {
  type        = string
  description = "The Azure region where the resources should be deployed."
  nullable    = false
}