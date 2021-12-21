variable "resource_group_name" {
  default = "ModeResourceGroup"
}

variable "location" {
    type = string
    description = "Azure location of storage account environment"
    default = "AustraliaSoutheast"
}
