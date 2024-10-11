<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-network-frontdoorwebapplicationfirewallpolicy

# Description

This Terraform module creates an **Azure CDN Front Door Web Application Firewall (WAF) policy** with customizable settings. It allows you to define both **managed** and **custom rules** to enhance the security of your Azure Front Door service.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

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

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 5.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_cdn_frontdoor_firewall_policy.waf_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_firewall_policy) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_role_assignment.this_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_mode"></a> [mode](#input\_mode)

Description: The mode of the WAF Policy. Possible values are 'Detection' and 'Prevention'.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the this resource.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name)

Description: SKU name of the WAF Policy. Possible values are 'Standard\_AzureFrontDoor' and 'Premium\_AzureFrontDoor'.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_custom_block_response_body"></a> [custom\_block\_response\_body](#input\_custom\_block\_response\_body)

Description: Optional. The custom block response body. If the action type is block, customer can override the response body setting this varibale. The body must be specified in base64 encoding

Type: `string`

Default: `null`

### <a name="input_custom_block_response_status_code"></a> [custom\_block\_response\_status\_code](#input\_custom\_block\_response\_status\_code)

Description: Optional. Customer can override the response status code setting this varibale. If a custom rule block's action is block, this is the response status code. Possible values are 200, 403, 405, 406, 429

Type: `number`

Default: `null`

### <a name="input_custom_rules"></a> [custom\_rules](#input\_custom\_rules)

Description: A list of custom rules to be applied to the WAF (Web Application Firewall) Policy.

Each custom rule object in the list must include:

- **name** (string, required): The name of the custom rule.

- **priority** (number, required): The priority of the custom rule. Lower numbers indicate higher priority.

- **type** (string, required): The type of the custom rule. Must be one of:
  - "MatchRule"
  - "RateLimitRule"

- **action** (string, required): The action to take when the rule matches. Must be one of:
  - "Allow"
  - "Block"
  - "Log"
  - "Redirect"

- **enabled** (bool, optional): Whether the rule is enabled. Defaults to `true`.

- **rate\_limit\_duration\_in\_minutes** (number, optional): The duration of the rate limit in minutes. Required if `type` is "RateLimitRule". Defaults to `1`.

- **rate\_limit\_threshold** (number, optional): The threshold of the rate limit. Required if `type` is "RateLimitRule". Defaults to `10`.

- **match\_conditions** (list of objects, required): A list of match conditions for the rule.

Each match condition object must include:

- **match\_variable** (string, required): The variable to match against. Must be one of:
  - "Cookies"
  - "PostArgs"
  - "QueryStrings"
  - "RemoteAddr"
  - "RequestBody"
  - "RequestHeader"
  - "RequestMethod"
  - "RequestUri"
  - "SocketAddr"

- **operator** (string, required): The comparison type to use for matching with the variable value. Must be one of:
  - "Any"
  - "BeginsWith"
  - "Contains"
  - "EndsWith"
  - "Equal"
  - "GeoMatch"
  - "GreaterThan"
  - "GreaterThanOrEqual"
  - "IPMatch"
  - "LessThan"
  - "LessThanOrEqual"
  - "RegEx"

- **match\_values** (list of strings, required): The values to match against. Up to **600** possible values across all `match_conditions` and `match_values` in all rules. Each string can be up to **256** characters in length.

- **selector** (string, optional): Required if `match_variable` is one of "QueryStrings", "PostArgs", "RequestHeader", or "Cookies". Specifies the key to match against.

- **negation\_condition** (bool, optional): Whether to negate the result of the condition. Defaults to `false`.

- **transforms** (list of strings, optional): Up to **5** transforms to apply. Each must be one of:
  - "Lowercase"
  - "RemoveNulls"
  - "Trim"
  - "Uppercase"
  - "URLDecode"
  - "URLEncode"

*Example 1: Basic Configuration with Default Rule Set*
```hcl
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
    }
]
```

Type:

```hcl
list(object({
    name                           = string               # Required
    priority                       = number               # Required
    type                           = string               # Must be "MatchRule" or "RateLimitRule"
    action                         = string               # Must be "Allow", "Block", "Log", "Redirect"
    enabled                        = optional(bool, true) # Default is true
    rate_limit_duration_in_minutes = optional(number, 1)  # Default is 1
    rate_limit_threshold           = optional(number, 10) # Default is 10
    match_conditions = list(object({
      match_variable     = string                     #Required, must be one of these values  "Cookies", "PostArgs", "QueryStrings", "RemoteAddr", "RequestBody" "RequestHeader", "RequestMethod", "RequestUri", "SocketAddr"
      operator           = string                     #(Required) Comparison type to use for matching with the variable value. Possible values are Any, BeginsWith, Contains, EndsWith, Equal, GeoMatch, GreaterThan, GreaterThanOrEqual, IPMatch, LessThan, LessThanOrEqual or RegEx
      match_values       = list(string)               # Required Up to 600 possible values to match. Limit is in total across all match_condition blocks and match_values arguments. String value itself can be up to 256 characters in length
      selector           = optional(string, null)     # (Optional) Match against a specific key if the match_variable is QueryString, PostArgs, RequestHeader or Cookies.
      negation_condition = optional(bool, null)       #(Optional) Should the result of the condition be negated.
      transforms         = optional(list(string), []) #(Optional) Up to 5 transforms to apply. Possible values are Lowercase, RemoveNulls, Trim, Uppercase, URLDecode or URLEncode.
    }))
  }))
```

Default: `[]`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_enabled"></a> [enabled](#input\_enabled)

Description: Indicates whether the WAF Policy is enabled or disabled. Default is true.

Type: `bool`

Default: `true`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_rules"></a> [managed\_rules](#input\_managed\_rules)

Description: The `managed_rules` variable is a list of managed rule configurations for Azure Web Application Firewall (WAF). It allows you to specify which managed rule sets to apply, customize their actions, and define any exclusions or overrides needed for your application.

**Variable Type**: `list(object({ ... }))`

---

### Structure of each Managed Rule:

- **type** *(string, Required)*:  
  Specifies the type of the managed rule set to use. Possible values are:
  - `"DefaultRuleSet"`
  - `"Microsoft_DefaultRuleSet"`
  - `"BotProtection"`
  - `"Microsoft_BotManagerRuleSet"`

- **action** *(string, Required)*:  
  The action to perform when the managed rule is matched or when the anomaly score exceeds a certain threshold, depending on the DRS version. Possible values include:
  - `"Allow"`
  - `"Log"`
  - `"Block"`
  - `"Redirect"`

- **version** *(string, Required)*:  
  The version of the managed rule set to apply. Available versions depend on the `type` selected:
  - For `"DefaultRuleSet"`: `"1.0"`, `"preview-0.1"`
  - For `"Microsoft_DefaultRuleSet"`: `"1.1"`, `"2.0"`, `"2.1"`
  - For `"BotProtection"`: `"preview-0.1"`
  - For `"Microsoft_BotManagerRuleSet"`: `"1.0"`

- **exclusions** *(optional, list(object({ ... })))*:  
  A list of exclusion blocks to specify variables that should be excluded from the managed rule processing.

  - **match\_variable** *(string, Required)*:  
    The type of variable to exclude. Possible values:
    - `"QueryStringArgNames"`
    - `"RequestBodyPostArgNames"`
    - `"RequestCookieNames"`
    - `"RequestHeaderNames"`
    - `"RequestBodyJsonArgNames"` *(Available only on DRS 2.0 or later)*

  - **selector** *(string, Required)*:  
    The specific value within the `match_variable` to exclude. If `operator` is `"EqualsAny"`, `selector` must be set to `"*"`.

  - **operator** *(string, Required)*:  
    The comparison operator for the `selector`. Possible values:
    - `"Equals"`
    - `"Contains"`
    - `"StartsWith"`
    - `"EndsWith"`
    - `"EqualsAny"`

- **overrides** *(optional, list(object({ ... })))*:  
  A list of override blocks to customize specific rule groups or rules within the managed rule set.

  - **rule\_group\_name** *(string, Required)*:  
    The name of the rule group to override.

  - **rules** *(optional, list(object({ ... })))*:  
    A list of rule blocks to override individual rules.

    - **rule\_id** *(string, Required)*:  
      The identifier of the managed rule to override.

    - **enabled** *(bool, Optional, default = false)*:  
      Indicates whether the managed rule override is enabled.

    - **action** *(string, Required)*:  
      The action to apply when the rule matches. Possible values depend on the DRS version:
      - For DRS 1.1 and below: `"Allow"`, `"Log"`, `"Block"`, `"Redirect"`
      - For DRS 2.0 and above: `"Log"`, `"AnomalyScoring"`

    - **exclusions** *(optional, list(object({ ... })))*:  
      Exclusions specific to this rule, with the same structure as above.

  - **exclusions** *(optional, list(object({ ... })))*:  
    Exclusions at the rule group level.

---

### Default Value:

```hcl
[
  # Managed Rule 1 - Microsoft_DefaultRuleSet 2.1
  {
    action  = "Block"
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
  },
  # Managed Rule 2 - Microsoft_BotManagerRuleSet 1.1
  {
    action  = "Block"
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.1"
  }
]
```
*Example 1: Basic Configuration with Default Rule Set*
```hcl
managed_rules = [
  {
    type    = "Microsoft_DefaultRuleSet"
    action  = "Block"
    version = "2.1"
  }
]
```  
This configuration applies the Microsoft Default Rule Set version 2.1 with a block action for matched rules.

*Example 2: Adding Exclusions*
```hcl
managed_rules = [
  {
    type       = "Microsoft_DefaultRuleSet"
    action     = "Block"
    version    = "2.1"
    exclusions = [
      {
        match_variable = "RequestHeaderNames"
        selector       = "User-Agent"
        operator       = "Equals"
      },
      {
        match_variable = "QueryStringArgNames"
        selector       = "session_id"
        operator       = "Contains"
      }
    ]
  }
]
```

Type:

```hcl
list(object({
    type    = string                    # (Required) The type of the managed rule. Possible values are "DefaultRuleSet" and "Microsoft_DefaultRuleSet", "BotProtection", "Microsoft_BotManagerRuleSet"
    action  = string                    # (Required) The action to perform for all DRS rules when the managed rule is matched or when the anomaly score is 5 or greater depending on which version of the DRS you are using. Possible values include Allow, Log, Block, and Redirect
    version = string                    # (Required) The version of the managed rule set to use. Possible values depends on which DRS type you are using, for the DefaultRuleSet type the possible values include 1.0 or preview-0.1. For Microsoft_DefaultRuleSet the possible values include 1.1, 2.0 or 2.1. For BotProtection the value must be preview-0.1 and for Microsoft_BotManagerRuleSet the value must be 1.0.
    exclusions = optional(list(object({ # (Optional) A list of Exclusion blocks.
      match_variable = string           # (Required) (Required) The variable type to be excluded. Possible values are QueryStringArgNames, RequestBodyPostArgNames, RequestCookieNames, RequestHeaderNames, RequestBodyJsonArgNames. Important: RequestBodyJsonArgNames is only available on Default Rule Set (DRS) 2.0 or later
      selector       = string           # (Required) Selector for the value in the match_variable attribute this exclusion applies to. selector must be set to * if operator is set to EqualsAny.
      operator       = string           # (Required) Comparison operator to apply to the selector when specifying which elements in the collection this exclusion applies to. Possible values are: Equals, Contains, StartsWith, EndsWith, EqualsAny
    })))

    overrides = optional(list(object({      # (Optional) A list of Override blocks.
      rule_group_name = string              # (Required) The name of the rule group to override.
      rules = optional(list(object({        # (Optional) A list of Rule blocks.
        rule_id = string                    # (Required) Identifier for the managed rule.
        enabled = optional(bool, false)     # (Optional) Is the managed rule override enabled or disabled. Defaults to false
        action  = string                    # (Required) The action to be applied when the managed rule matches or when the anomaly score is 5 or greater. Possible values for DRS 1.1 and below are Allow, Log, Block, and Redirect. For DRS 2.0 and above the possible values are Log or AnomalyScoring.
        exclusions = optional(list(object({ # (Optional) A list of Exclusion blocks.
          match_variable = string           # (Required) (Required) The variable type to be excluded. Possible values are QueryStringArgNames, RequestBodyPostArgNames, RequestCookieNames, RequestHeaderNames, RequestBodyJsonArgNames. Important: RequestBodyJsonArgNames is only available on Default Rule Set (DRS) 2.0 or later
          selector       = string           # (Required) Selector for the value in the match_variable attribute this exclusion applies to. selector must be set to * if operator is set to EqualsAny.
          operator       = string           # (Required) Comparison operator to apply to the selector when specifying which elements in the collection this exclusion applies to. Possible values are: Equals, Contains, StartsWith, EndsWith, EqualsAny
        })))
      })))

      exclusions = optional(list(object({ # (Optional) A list of Exclusion blocks.
        match_variable = string           # (Required) (Required) The variable type to be excluded. Possible values are QueryStringArgNames, RequestBodyPostArgNames, RequestCookieNames, RequestHeaderNames, RequestBodyJsonArgNames. Important: RequestBodyJsonArgNames is only available on Default Rule Set (DRS) 2.0 or later
        selector       = string           # (Required) Selector for the value in the match_variable attribute this exclusion applies to. selector must be set to * if operator is set to EqualsAny.
        operator       = string           # (Required) Comparison operator to apply to the selector when specifying which elements in the collection this exclusion applies to. Possible values are: Equals, Contains, StartsWith, EndsWith, EqualsAny
      })))

    })))
  }))
```

Default:

```json
[
  {
    "action": "Block",
    "type": "Microsoft_DefaultRuleSet",
    "version": "2.1"
  },
  {
    "action": "Block",
    "type": "Microsoft_BotManagerRuleSet",
    "version": "1.1"
  }
]
```

### <a name="input_redirect_url"></a> [redirect\_url](#input\_redirect\_url)

Description: Optional. The redirect URL for the WAF Policy.

Type: `string`

Default: `null`

### <a name="input_request_body_check_enabled"></a> [request\_body\_check\_enabled](#input\_request\_body\_check\_enabled)

Description: Indicates whether to enable request body check. Default is true.

Type: `bool`

Default: `true`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role definitions and scopes to be assigned as part of this resources implementation.  Two forms are supported. Assignments against this virtual machine resource scope and assignments to external resource scopes using the system managed identity.

- `<map key>` - Use a custom map key to define each role assignment configuration for this virtual machine
  - `principal_id`                               = (optional) - The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to. Changing this forces a new resource to be created.
  - `role_definition_id_or_name`                 = (Optional) - The Scoped-ID of the Role Definition or the built-in role name. Changing this forces a new resource to be created. Conflicts with role\_definition\_name
  - `condition`                                  = (Optional) - The condition that limits the resources that the role can be assigned to. Changing this forces a new resource to be created.
  - `condition_version`                          = (Optional) - The version of the condition. Possible values are 1.0 or 2.0. Changing this forces a new resource to be created.
  - `description`                                = (Optional) - The description for this Role Assignment. Changing this forces a new resource to be created.
  - `skip_service_principal_aad_check`           = (Optional) - If the principal\_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal\_id is a Service Principal identity. Defaults to false.
  - `delegated_managed_identity_resource_id`     = (Optional) - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.  
  - `principal_type`                             = (Optional) - The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

Example Inputs:

```hcl
#typical assignment example. It is also common for the scope resource ID to be a terraform resource reference like azurerm_resource_group.example.id
role_assignments = {
  role_assignment_1 = {
    #assign a built-in role to the virtual machine
    role_definition_id_or_name                 = "Storage Blob Data Contributor"
    principal_id                               = data.azuread_client_config.current.object_id
    description                                = "Example for assigning a role to an existing principal for the virtual machine scope"        
  }
}
```

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    description                            = optional(string, null)
    principal_type                         = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)

    }
  ))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: This is the full output for the resource.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ID of the WAF Policy.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->