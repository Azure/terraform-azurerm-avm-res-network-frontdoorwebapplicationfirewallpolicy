terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}


locals {
  enable_telemetry = true
  location         = "eastus2"
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
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
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
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...

  name                = "mywafpolicy${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = local.enable_telemetry

  mode     = "Prevention"
  sku_name = "Premium_AzureFrontDoor"
}
