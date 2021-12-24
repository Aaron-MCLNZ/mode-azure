
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 1.1.0"
}

# Configure the Azure provider
provider "azurerm" {
  features {
      key_vault {
      purge_soft_delete_on_destroy = true
      }

  subscription_id = var.subscription_id 
  client_id = var.client_id
  client_certificate_path = var.client_certificate_path
  client_certificate_password = var.client_certificate_password
  tenant_id = var.tenant_id
  }
  
}

# Create Resource Group
resource "azurerm_resource_group" "moderg" {
  name     = var.moderg
  location = var.location

  tags = {
    Environment = "Getting Started"
    Team = "Mode Projects"
  }
}

# Create Key Vault

resource "azurerm_key_vault" "modekv" {
  name                        = var.modekv
  location                    = var.location
  resource_group_name         = var.moderg
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

# Create Storage Account
module "storage_account" {
  source    = "./modules/storage-account"

  saname    = "ModeStorage"
  rgname    = azurerm_resource_group.moderg.name
  location  = azurerm_resource_group.moderg.location
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
  resource_group_name = azurerm_resource_group.moderg.name
}

# Create Azure Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "mode-prod-auseast-001 "
  resource_group_name  = azurerm_resource_group.moderg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.3.0.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "pip-mode-prod-auseast-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.moderg.name
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }

}

# Create network security group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-sshallow-001 "
  location            = var.location
  resource_group_name = azurerm_resource_group.moderg.name

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
  resource_group_name       = azurerm_resource_group.moderg.name
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
  resource_group_name   = azurerm_resource_group.moderg.name
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