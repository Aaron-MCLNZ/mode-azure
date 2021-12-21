variable "resource_group_name" {
  default = "myTFResourceGroup"
}

variable "rgname" {
  type = string
  description = "Name of resource group"
}

variable "saname" {
    type = string
    description = "Name of storage account"
}

variable "location" {
    type = string
    description = "Azure location of storage account environment"
    default = "AustraliaSoutheast"
}
