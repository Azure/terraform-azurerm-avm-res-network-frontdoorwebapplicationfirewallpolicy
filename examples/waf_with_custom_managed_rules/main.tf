terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.0.2"
    }
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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  skip_provider_registration = true
}


locals {
  enable_telemetry = true #enable_telemetry is a variable that controls whether or not telemetry is enabled for the module.
  location         = "eastus2"
  tags = {
    scenario     = "WAF with custom and managed rules"
    project      = "Web Application Firewall for Azure Front Door"
    createdby    = "Web Application Firewall Policy AVM"
    hidden-title = "WAF for AFD with custom and managed rules"
    delete       = "yes"
  }
}

data "azuread_client_config" "current" {}

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

module "test" {
  source = "../.."
  # source  = "Azure/avm-res-network-frontdoorapplicationfirewallpolicy/azurerm"
  # version = "0.1.0"

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
    #Managed Rule 1 - Microsoft_DefaultRuleSet
    {
      action  = "Block"
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"

      #Example of exclusion
      exclusions = [
        {
          match_variable = "QueryStringArgNames"
          operator       = "Equals"
          selector       = "not_suspicious"
        }
      ]

      #Example of override
      overrides = [{
        rule_group_name = "PHP"
        rules = [{
          rule_id = "933100"
          enabled = false
          action  = "AnomalyScoring"
          },
          {
            rule_id = "933110"
            enabled = true
            action  = "AnomalyScoring"
        }]
        },
        {
          rule_group_name = "SQLI"
          rules = [{
            rule_id = "942100"
            enabled = false
            action  = "AnomalyScoring"
            },
            {
              rule_id = "942200"
              action  = "AnomalyScoring"

              exclusions = [{
                match_variable = "QueryStringArgNames"
                operator       = "Equals"
                selector       = "innocent"
              }]
          }]

          exclusions = [{
            match_variable = "QueryStringArgNames"
            operator       = "Equals"
            selector       = "really_not_suspicious"
          }]
        }
      ]
    },
    #Managed Rule 2 - Microsoft_BotManagerRuleSet
    {
      action  = "Block"
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.1"
    }
  ]

  role_assignments = {
    role_assignment_1 = {
      #assign a built-in role to the virtual machine
      role_definition_id_or_name = "Contributor"
      principal_id               = data.azuread_client_config.current.object_id
      description                = "Example for assigning a role to an existing principal for WAF scope"
    }
  }

}
