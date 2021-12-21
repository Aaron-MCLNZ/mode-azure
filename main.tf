# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Getting Started"
    Team = "Mode Projects"
  }
}

# Create Storage Account
module "storage_account" {
  source    = "./modules/storage-account"

  saname    = "ModeStorage"
  rgname    = azurerm_resource_group.rg.name
  location  = azurerm_resource_group.rg.location
}

# Save Storage Key to Vault
resource "azurerm_key_vault_secret" "stasecret" {
  name         = "ModeStorage-secret"
  value        = module.storage_account.primary_key
  key_vault_id = azurerm_key_vault.kv.id
}

##### NETWORKING #####

# Create Azure Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name     = "ModeVnet"
  address_space = ["10.0.0.0/16"]
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create Azure Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "mode-prod-auseast-001 "
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.3.0.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "pip-mode-prod-auseast-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }

}

# Create network security group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-sshallow-001 "
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                      = "nic-01-modevm-prod-001 "
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  #network_security_group_id = azurerm_network_security_group.nsg.name

  ip_configuration {
    name                          = "niccfg-modevm"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "modevm01"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "modevm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "mode-prd-vm-01"
    admin_username = "modeadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}