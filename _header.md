# terraform-azurerm-avm-res-network-frontdoorwebapplicationfirewallpolicy

# Description

This Terraform module creates an **Azure CDN Front Door Web Application Firewall (WAF) policy** with customizable settings. It allows you to define both **managed** and **custom rules** to enhance the security of your Azure Front Door service.

# Features

- **Configurable WAF Mode**: Set the WAF policy mode to either `Detection` or `Prevention`.
- **Custom Block Responses**: Define custom response bodies and status codes for blocked requests.
- **Custom Rules**: Implement custom WAF rules with specific match conditions, actions, and priorities.
- **Managed Rules**: Utilize Azure's managed rule sets with options for overrides and exclusions.
- **Dynamic Configuration**: Leverage dynamic blocks to configure rules based on variable inputs.
- **Tagging Support**: Add tags to your WAF policy for better resource management.

# Prerequisites

- **Terraform**: Install Terraform version 0.12 or later.
- **Azure Subscription**: An active Azure subscription with the necessary permissions.


# Usage

An example of using the module in a Terraform configuraiton:

# Usage Example

Below is an example of how to utilize this Terraform module to create an Azure CDN Front Door WAF policy.

## 1. Create a Terraform Configuration File

Create a file named `main.tf` and include the following content:

```hcl
# Instantiate the WAF Policy Module
module "frontdoor_waf_policy" {
  source  = "Azure/terraform-azurerm-avm-res-network-frontdoorwebapplicationfirewallpolicy/azurerm"
  version = "0.1.0"

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

```

# Variables

| Name                             | Type                           | Default Value | Description                                                                                                                                                                                                                                                                                            |
|----------------------------------|--------------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `mode`                           | `string`                       | n/a           | The mode of the WAF Policy. Possible values are `'Detection'` and `'Prevention'`.                                                                                                                                                                                                                      |
| `name`                           | `string`                       | n/a           | The name of this resource.                                                                                                                                                                                                                                                                             |
| `resource_group_name`            | `string`                       | n/a           | The resource group where the resources will be deployed.                                                                                                                                                                                                                                               |
| `sku_name`                       | `string`                       | n/a           | SKU name of the WAF Policy. Possible values are `'Standard_AzureFrontDoor'` and `'Premium_AzureFrontDoor'`.                                                                                                                                                                                            |
| `custom_block_response_body`     | `string`                       | `null`        | Optional. The custom block response body. If the action type is block, you can override the response body by setting this variable. The body must be specified in base64 encoding.                                                                                                                      |
| `custom_block_response_status_code` | `number`                    | `null`        | Optional. Override the response status code by setting this variable when a custom rule's action is block. Possible values are `200`, `403`, `405`, `406`, `429`.                                                                                                                                       |
| `custom_rules`                   | `list(object)`                 | `[]`          | A list of custom rules to be applied to the WAF Policy. See [Custom Rules](#custom-rules) for detailed structure.                                                                                                                                                                                      |                                                                                                                                                        |
| `enable_telemetry`               | `bool`                         | `true`        | Controls whether telemetry is enabled for the module. If set to `false`, no telemetry will be collected.                                                                                                                                                                                                |
| `enabled`                        | `bool`                         | `true`        | Indicates whether the WAF Policy is enabled or disabled. Default is `true`.                                                                                                                                                                                                                            |
| `managed_rules`                  | `list(object)`                 | See default value | A list of managed rule configurations for Azure WAF. See [Managed Rules](#managed-rules) for detailed structure.                                                                                                                                                                                       |
| `redirect_url`                   | `string`                       | `null`        | Optional. The redirect URL for the WAF Policy.                                                                                                                                                                                                                                                         |
| `request_body_check_enabled`     | `bool`                         | `true`        | Indicates whether to enable request body check. Default is `true`.                                                                                                                                                                                                                                     |
| `role_assignments`               | `map(object)`                  | `{}`          | A map of role definitions and scopes to be assigned as part of this resource's implementation. See [Role Assignments](#role-assignments) for detailed structure.                                                                                                                                       |
| `tags`                           | `map(string)`                  | `null`        | (Optional) Tags of the resource.                                                                                                                                                                                                                                                                       |
| `lock`                           | `object`                       | `null`        | Controls the Resource Lock configuration for this resource. See [Lock](#lock) for detailed structure.                                                                                                                                                                                                  |
