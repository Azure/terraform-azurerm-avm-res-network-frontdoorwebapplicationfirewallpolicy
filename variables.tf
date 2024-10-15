variable "mode" {
  type        = string
  description = "The mode of the WAF Policy. Possible values are 'Detection' and 'Prevention'."

  validation {
    condition     = can(index(["Detection", "Prevention"], var.mode))
    error_message = "The mode must be either 'Detection' or 'Prevention'."
  }
}

variable "name" {
  type        = string #Name can be only lowercase letters, numbers, no spaces, and between 1 and 80 characters long.
  description = "The name of the this resource."

  validation {
    condition     = can(regex("^[a-z0-9]{1,80}$", var.name))
    error_message = "The name can only contain lowercase letters and numbers, no spaces, and must be between 1 and 80 characters long."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "sku_name" {
  type        = string
  description = "SKU name of the WAF Policy. Possible values are 'Standard_AzureFrontDoor' and 'Premium_AzureFrontDoor'."

  validation {
    condition     = can(index(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name))
    error_message = "The SKU name must be either 'Standard_AzureFrontDoor' or 'Premium_AzureFrontDoor'."
  }
}

variable "custom_block_response_body" {
  type        = string
  default     = null
  description = "Optional. The custom block response body. If the action type is block, customer can override the response body setting this varibale. The body must be specified in base64 encoding"

  validation {
    condition     = var.custom_block_response_body == null || can(regex("^[A-Za-z0-9+/=]+$", var.custom_block_response_body))
    error_message = "The string must be a valid base64-encoded value."
  }
}

variable "custom_block_response_status_code" {
  type        = number
  default     = null
  description = "Optional. Customer can override the response status code setting this varibale. If a custom rule block's action is block, this is the response status code. Possible values are 200, 403, 405, 406, 429"

  validation {
    condition     = var.custom_block_response_status_code == null || can(index([200, 403, 405, 406, 429], var.custom_block_response_status_code))
    error_message = "The custom block response status code must be one of 200, 403, 405, 406, 429"
  }
}

variable "custom_rules" {
  type = list(object({
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
  default     = []
  description = <<DESCRIPTION
A list of custom rules to be applied to the WAF (Web Application Firewall) Policy.

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

- **rate_limit_duration_in_minutes** (number, optional): The duration of the rate limit in minutes. Required if `type` is "RateLimitRule". Defaults to `1`.

- **rate_limit_threshold** (number, optional): The threshold of the rate limit. Required if `type` is "RateLimitRule". Defaults to `10`.

- **match_conditions** (list of objects, required): A list of match conditions for the rule.

Each match condition object must include:

- **match_variable** (string, required): The variable to match against. Must be one of:
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

- **match_values** (list of strings, required): The values to match against. Up to **600** possible values across all `match_conditions` and `match_values` in all rules. Each string can be up to **256** characters in length.

- **selector** (string, optional): Required if `match_variable` is one of "QueryStrings", "PostArgs", "RequestHeader", or "Cookies". Specifies the key to match against.

- **negation_condition** (bool, optional): Whether to negate the result of the condition. Defaults to `false`.

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

DESCRIPTION
  nullable    = false
}

####################### Required AVM interfaces
# remove only if not supported by the resource
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Indicates whether the WAF Policy is enabled or disabled. Default is true."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "managed_rules" {
  type = list(object({
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
  default = [
    #Managed Rule 1 - Microsoft_DefaultRuleSet 2.1
    {
      action  = "Block"
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
    },
    #Managed Rule 2 - Microsoft_BotManagerRuleSet 1.1
    {
      action  = "Block"
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.1"
    }
  ]
  description = <<DESCRIPTION
The `managed_rules` variable is a list of managed rule configurations for Azure Web Application Firewall (WAF). It allows you to specify which managed rule sets to apply, customize their actions, and define any exclusions or overrides needed for your application.

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

  - **match_variable** *(string, Required)*:  
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

  - **rule_group_name** *(string, Required)*:  
    The name of the rule group to override.

  - **rules** *(optional, list(object({ ... })))*:  
    A list of rule blocks to override individual rules.

    - **rule_id** *(string, Required)*:  
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
      }]
  }
]
``` 

DESCRIPTION
  nullable    = false
}

variable "redirect_url" {
  type        = string
  default     = null
  description = "Optional. The redirect URL for the WAF Policy."

  validation {
    condition     = var.redirect_url == null || var.redirect_url == "" || can(regex("https?://[a-zA-Z0-9-]+\\.[a-zA-Z0-9-]+", var.redirect_url))
    error_message = "The redirect URL must be a valid URL."
  }
}

variable "request_body_check_enabled" {
  type        = bool
  default     = true
  description = "Indicates whether to enable request body check. Default is true."
}

variable "role_assignments" {
  type = map(object({
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
  default     = {}
  description = <<ROLE_ASSIGNMENTS
A map of role definitions and scopes to be assigned as part of this resources implementation.  Two forms are supported. Assignments against this virtual machine resource scope and assignments to external resource scopes using the system managed identity.

- `<map key>` - Use a custom map key to define each role assignment configuration for this virtual machine
  - `principal_id`                               = (optional) - The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to. Changing this forces a new resource to be created.
  - `role_definition_id_or_name`                 = (Optional) - The Scoped-ID of the Role Definition or the built-in role name. Changing this forces a new resource to be created. Conflicts with role_definition_name 
  - `condition`                                  = (Optional) - The condition that limits the resources that the role can be assigned to. Changing this forces a new resource to be created.
  - `condition_version`                          = (Optional) - The version of the condition. Possible values are 1.0 or 2.0. Changing this forces a new resource to be created.
  - `description`                                = (Optional) - The description for this Role Assignment. Changing this forces a new resource to be created.
  - `skip_service_principal_aad_check`           = (Optional) - If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. Defaults to false.
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
ROLE_ASSIGNMENTS
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
