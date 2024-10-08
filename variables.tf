variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
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

variable "enabled" {
  type        = bool
  default     = true
  description = "Indicates whether the WAF Policy is enabled or disabled. Default is true."
}

variable "mode" {
  type        = string
  description = "The mode of the WAF Policy. Possible values are 'Detection' and 'Prevention'."
  validation {
    condition     = can(index(["Detection", "Prevention"], var.mode))
    error_message = "The mode must be either 'Detection' or 'Prevention'."
  }
}

variable "request_body_check_enabled" {
  type        = bool
  default     = true
  description = "Indicates whether to enable request body check. Default is true."
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

variable "custom_block_response_body" {
  type        = string
  default     = null
  description = "Optional. The custom block response body. If the action type is block, customer can override the response body setting this varibale. The body must be specified in base64 encoding"

  validation {
    condition     = can(regex("^[A-Za-z0-9+/=]+$", var.custom_block_response_body))
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
  default = []






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

DESCRIPTION
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
        enabled = optional(bool, false)     #(Optional) Is the managed rule override enabled or disabled. Defaults to false
        action  = string                    # (Required) The action to be applied when the managed rule matches or when the anomaly score is 5 or greater. Possible values for DRS 1.1 and below are Allow, Log, Block, and Redirect. For DRS 2.0 and above the possible values are Log or AnomalyScoring.
        exclusions = optional(list(object({ # (Optional) A list of Exclusion blocks.
          match_variable = string           # (Required) (Required) The variable type to be excluded. Possible values are QueryStringArgNames, RequestBodyPostArgNames, RequestCookieNames, RequestHeaderNames, RequestBodyJsonArgNames. Important: RequestBodyJsonArgNames is only available on Default Rule Set (DRS) 2.0 or later
          selector       = string           # (Required) Selector for the value in the match_variable attribute this exclusion applies to. selector must be set to * if operator is set to EqualsAny.
          operator       = string           # (Required) Comparison operator to apply to the selector when specifying which elements in the collection this exclusion applies to. Possible values are: Equals, Contains, StartsWith, EndsWith, EqualsAny
        })))
      })))


    })))
  }))

  default = []

  description = <<DESCRIPTION
A list of managed rules to be applied to the WAF (Web Application Firewall) Policy.
The Standard_AzureFrontDoor Front Door Firewall Policy sku may contain custom rules only. The Premium_AzureFrontDoor Front Door Firewall Policy skus may contain both custom and managed rules.
  DESCRIPTION
}



####################### Required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.
DESCRIPTION  
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION  
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

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

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of this resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false
}

# This variable is used to determine if the private_dns_zone_group block should be included,
# or if it is to be managed externally, e.g. using Azure Policy.
# https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault/issues/32
# Alternatively you can use AzAPI, which does not have this issue.
variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
