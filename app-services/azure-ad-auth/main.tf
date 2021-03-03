terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.49.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=1.4.0"
    }
  }
}

provider "azuread" {
}
provider "azurerm" {
    features {}
}

# Variable definitions
variable "location" { type = string }
variable "name" { type = string }
variable "domain" { type = string }
variable "tenant" { type = string }
variable "resource_group" {
    type = string
    default = "AzureAD-Auth-RG"
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

# App Service and Insights
resource "azurerm_app_service_plan" "web" {
  name                = var.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "web" {
  name                = var.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.web.id

  site_config {
    dotnet_framework_version = "v4.0"
  }

  app_settings = {
    "APPLICATIONINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.ai.instrumentation_key
    "Domain" = var.domain
    "TenantId" = var.tenant
    "ClientId" = azuread_application.TodoListAPI.application_id
    "WEBSITE_RUN_FROM_PACKAGE" = "https://github.com/ralacher/azure-demos/releases/download/azure-ad-angular-aspnetcore/aspnetcore.zip"
  }
}

resource "azurerm_application_insights" "ai" {
  name                = var.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

output "clientId" {
  value = azuread_application.TodoListSPA.application_id
}

output "redirectUri" {
  value = azurerm_storage_account.sa.primary_web_endpoint
}

output "resourceUri" {
  value = azurerm_app_service.web.default_site_hostname
}

output "resourceScope" {
  value = "https://todolistapi/access_as_user"
}

output "blobUrl" {
  value = azurerm_storage_account.sa.primary_web_endpoint
}

output "blobAccount" {
  value = azurerm_storage_account.sa.name
}
