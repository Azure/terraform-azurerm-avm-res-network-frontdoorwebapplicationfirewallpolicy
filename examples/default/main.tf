terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  resource_provider_registrations = "none"
}

locals {
  location = "eastus2"
  tags = {
    scenario     = "Default"
    project      = "Web Application Firewall for Azure Front Door"
    createdby    = "Web Application Firewall Policy AVM"
    hidden-title = "WAF for AFD Default configuration"
    delete       = "yes"
  }
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
}

# Create a random string for the suffix
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# Create a WAF policy in its simplest form
module "test" {
  source = "../.."

  location            = var.location
  mode                = "Prevention"
  name                = "mywafpolicy${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Premium_AzureFrontDoor"
  enable_telemetry    = var.enable_telemetry
}
