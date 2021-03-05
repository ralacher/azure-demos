terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.49.0"
    }
    backend "azurerm" {
      resource_group_name  = "Identity-RG"
      storage_account_name = "STORAGE_ACCOUNT_NAME"
      container_name       = "tfstate"
      key                  = "managed-app.tfstate"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "location" {
  default = "eastus2"
}

# Data sources
data "azurerm_client_config" "current" {}
data "azurerm_role_definition" "owner" {
  name = "Owner"
}

# Definitions
resource "azurerm_resource_group" "managed-app" {
  name = "ManagedApplication-RG"
  location = var.location
}

resource "azurerm_managed_application_definition" "virtualMachine" {
  name                = "apache-linux"
  location            = azurerm_resource_group.managed-app.location
  resource_group_name = azurerm_resource_group.managed-app.name
  lock_level          = "ReadOnly"
  package_file_uri    = "https://github.com/ralacher/azure-demos/releases/download/managed-application/virtual-machine.zip"
  display_name        = "Apache Web Server"
  description         = "RedHat Enterprise Linux VM with Apache installed"

  authorization {
    service_principal_id = data.azurerm_client_config.current.object_id
    role_definition_id   = data.azurerm_role_definition.owner.id
  }
}