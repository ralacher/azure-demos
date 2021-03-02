provider "azuread" {
    version = "1.4.0"
}
provider "azurerm" {
    version = "2.49.0"
    features {}
}

# Variable definitions
variable "location" {
    type = string
}

variable "resource_group" {
    type = string
    default = "AzureAD-Auth-RG"
}

variable "name" {
    type = "string"
}

# App Registration for the Todo List API
resource "azuread_application" "TodoListAPI" {
  display_name               = "Todo List API"
  identifier_uris            = ["https://todolistapi"]
  reply_urls                 = []
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
  owners                     = []

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }

  app_role {
    allowed_member_types = [
      "User"
    ]
    description  = "Admins can read any user's todo list."
    display_name = "TaskAdmin"
    is_enabled   = true
    value        = "TaskAdmin"
  }

  app_role {
    allowed_member_types = [
      "User"
    ]
    description  = "Users can read and modify their todo lists."
    display_name = "TaskUser"
    is_enabled   = true
    value        = "TaskUser"
  }
}

resource "azuread_application_oauth2_permission" "access" {
  application_object_id      = azuread_application.TodoListAPI.object_id
    admin_consent_description  = "Allows the app to access TodoListAPI as the signed-in user."
    admin_consent_display_name = "Access TodoListAPI"
    is_enabled                 = true
    type                       = "User"
    user_consent_description   = "Allow the application to access TodoListAPI on your behalf."
    user_consent_display_name  = "Access TodoListAPI"
    value                      = "access_as_user"
}

# App Registration for the Todo List SPA
resource "azuread_application" "TodoListSPA" {
  display_name               = "Todo List SPA"
  identifier_uris            = []
  reply_urls                 = [azurerm_storage_account.sa.primary_web_endpoint]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
  owners                     = []

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }

  required_resource_access {
      resource_app_id = azuread_application.TodoListAPI.application_id

      resource_access {
          id = azuread_application_oauth2_permission.access.permission_id
          type = "Scope"
      }
  }

  app_role {
    allowed_member_types = [
      "User"
    ]
    description  = "Admins can read any user's todo list."
    display_name = "TaskAdmin"
    is_enabled   = true
    value        = "TaskAdmin"
  }

  app_role {
    allowed_member_types = [
      "User"
    ]
    description  = "Users can read and modify their todo lists."
    display_name = "TaskUser"
    is_enabled   = true
    value        = "TaskUser"
  }
}

# Resource Group for the deployment
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# Storage Account to host the Angular SPA
resource "azurerm_storage_account" "sa" {
  name                     = replace(var.name, "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
  enable_https_traffic_only = true
  is_hns_enabled = false
  static_website {}
}
