variable "moderg" {
  type = string
  description = "Mode Resources Group"
  default = "ModeResourceGroup"
}

variable "location" {
    type = string
    description = "Azure location of storage account environment"
    default = "AustraliaSoutheast"
}

variable "client_certificate_path" {
    type = string
    description = "Path to Client Certificate"
    default = "value"
}

variable "client_certificate_password" {
    type = string
    description = "Password for Client Certificate"
    default = "value"
}

variable "subscription_id" {
  type = string
  description = "Subscription ID of Tenant"
  default = ""
}

variable "client_id" {
  type = string
  description = "ID of client connection"
  default = ""
}

variable "tenant_id" {
  type = string
  description = "ID of Tenant"
  default = ""
}

variable "modekv" {
  type = string
  description = "Name of Keyvault"
  default = "modekeyvault"
}