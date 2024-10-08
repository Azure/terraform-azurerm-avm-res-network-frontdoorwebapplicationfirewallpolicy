# Create the WAF Policy for Front Door
resource "azurerm_cdn_frontdoor_firewall_policy" "waf_policy" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  mode                              = var.mode
  sku_name                          = var.sku_name
  enabled                           = var.enabled
  request_body_check_enabled        = var.request_body_check_enabled
  redirect_url                      = var.redirect_url
  custom_block_response_body        = var.custom_block_response_body
  custom_block_response_status_code = var.custom_block_response_status_code


  dynamic "custom_rule" {
    for_each = var.custom_rules
    content {
      name                           = custom_rule.value.name
      priority                       = custom_rule.value.priority
      type                           = custom_rule.value.type
      action                         = custom_rule.value.action
      enabled                        = lookup(custom_rule.value, "enabled", true)
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes #lookup? 
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold           #lookup? 
      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions
        content {
          match_variable     = match_condition.value.match_variable
          operator           = match_condition.value.operator
          match_values       = match_condition.value.match_values
          selector           = lookup(match_condition.value, "selector", null)
          transforms         = lookup(match_condition.value, "transforms", [])
          negation_condition = lookup(match_condition.value, "negation_condition", null)
        }
      }
    }
  }

  dynamic "managed_rule" {
    for_each = var.managed_rules
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version
      action  = managed_rule.value.action

      dynamic "exclusion" {
        for_each = managed_rule.value.exclusions != null ? managed_rule.value.exclusions : []
        content {
          match_variable = exclusion.value.match_variable
          selector       = exclusion.value.selector
          operator       = exclusion.value.operator
        }
      }

      dynamic "override" {
        for_each = managed_rule.value.overrides != null ? managed_rule.value.overrides : []
        content {
          rule_group_name = override.value.rule_group_name

          dynamic "rule" {
            for_each = override.value.rules != null ? override.value.rules : []
            content {
              rule_id = rule.value.rule_id
              action  = rule.value.action
              enabled = lookup(rule.value, "enabled", null)

              dynamic "exclusion" {
                for_each = rule.value.exclusions != null ? rule.value.exclusions : []
                content {
                  match_variable = exclusion.value.match_variable
                  selector       = exclusion.value.selector
                  operator       = exclusion.value.operator
                }
              }
            }
          }
        }
      }
    }
  }
}









# # required AVM resources interfaces
# resource "azurerm_management_lock" "this" {
#   count = var.lock != null ? 1 : 0

#   lock_level = var.lock.kind
#   name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
#   scope      = azurerm_MY_RESOURCE.this.id # TODO: Replace with your azurerm resource name
#   notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
# }

