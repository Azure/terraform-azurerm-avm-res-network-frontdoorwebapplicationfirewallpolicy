terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
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
  enable_telemetry = true #enable_telemetry is a variable that controls whether or not telemetry is enabled for the module.
  location         = "eastus"
  tags = {
    scenario  = "Default"
    project   = "Web Application Firewall for Azure Front Door"
    createdby = "Web Application Firewall Policy AVM"
    delete    = "yes"
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


# # Create a WAF policy in its simplest form
# module "test" {
#   source = "../../"
#   # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
#   # ...

#   location            = azurerm_resource_group.this.location
#   name                = "mywafpolicy${random_string.suffix.result}"
#   resource_group_name = azurerm_resource_group.this.name
#   enable_telemetry    = local.enable_telemetry

#   mode     = "Prevention"
#   sku_name = "Premium_AzureFrontDoor"
# }

module "test" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...

  location            = azurerm_resource_group.this.location
  name                = "mywafpolicy${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = local.enable_telemetry
  mode                = "Prevention"
  sku_name            = "Premium_AzureFrontDoor"

  request_body_check_enabled        = true
  redirect_url                      = "https://learn.microsoft.com/docs/"
  custom_block_response_status_code = 405
  custom_block_response_body        = base64encode("Blocked by WAF")

  custom_rules = [
    #custom rule 1
    {
      name     = "RateLimitRule1"
      priority = 100
      type     = "RateLimitRule"
      action   = "Block"
      match_conditions = [{
        match_variable = "QueryString"
        operator       = "Contains"
        match_values   = ["promo"]
        }
      ]
    },
    #custom rule 2
    {
      name     = "GeographicRule1"
      priority = 101
      type     = "MatchRule"
      action   = "Block"
      match_conditions = [{
        match_variable = "RemoteAddr"
        operator       = "GeoMatch"
        match_values   = ["MX", "AR"]
        },
        {
          match_variable = "RemoteAddr"
          operator       = "IPMatch"
          match_values   = ["10.10.10.0/24"]
        }
      ]
    },
    #custom rule 3
    {
      name     = "QueryStringSizeRule1"
      priority = 102
      type     = "MatchRule"
      action   = "Block"
      match_conditions = [{
        match_variable = "RequestUri"
        operator       = "GreaterThan"
        match_values   = ["200"]
        transforms     = ["UrlDecode", "Trim", "Lowercase"]
      }]
    }
  ]

  managed_rules = [
    #Managed Rule 1
    {
      action  = "Block"
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.1"
    },
    #Managed Rule 2
    {
      action  = "Block"
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
      overrides = [
        #Override 1
        {
          rule_group_name = "SQLI"
          rules = [
            {
              action  = "AnomalyScoring"
              rule_id = "933140"
              enabled = true
              exclusions = [{
                match_variable = "RequestHeaderNames"
                operator       = "Contains"
                selector       = "SampleHeader"
                },
                {
                  match_variable = "QueryStringArgNames"
                  operator       = "Equals"
                  selector       = "SampleQueryArgs"
                }
              ]
          }]

        },
        #Override 2
        {
          rule_group_name = "JAVA"
          rules = [
            {
              action  = "AnomalyScoring"
              rule_id = "944240"
              enabled = true

              exclusions = [{
                match_variable = "RequestCookieNames"
                operator       = "EqualsAny"
                selector       = "*"
                }
              ]
          }]
        }

      ]
    }
  ]

}
