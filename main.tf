# Create the WAF Policy for Front Door
resource "azurerm_cdn_frontdoor_firewall_policy" "waf_policy" {
  mode                              = var.mode
  name                              = var.name
  resource_group_name               = var.resource_group_name
  sku_name                          = var.sku_name
  custom_block_response_body        = var.custom_block_response_body
  custom_block_response_status_code = var.custom_block_response_status_code
  enabled                           = var.enabled
  redirect_url                      = var.redirect_url
  request_body_check_enabled        = var.request_body_check_enabled
  tags                              = var.tags

  dynamic "custom_rule" {
    for_each = var.custom_rules

    content {
      action                         = custom_rule.value.action
      name                           = custom_rule.value.name
      type                           = custom_rule.value.type
      enabled                        = lookup(custom_rule.value, "enabled", true)
      priority                       = custom_rule.value.priority
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold

      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions

        content {
          match_values       = match_condition.value.match_values
          match_variable     = match_condition.value.match_variable
          operator           = match_condition.value.operator
          negation_condition = lookup(match_condition.value, "negation_condition", null)
          selector           = lookup(match_condition.value, "selector", null)
          transforms         = lookup(match_condition.value, "transforms", [])
        }
      }
    }
  }
  dynamic "managed_rule" {
    for_each = var.managed_rules

    content {
      action  = managed_rule.value.action
      type    = managed_rule.value.type
      version = managed_rule.value.version

      dynamic "exclusion" {
        for_each = managed_rule.value.exclusions != null ? managed_rule.value.exclusions : []

        content {
          match_variable = exclusion.value.match_variable
          operator       = exclusion.value.operator
          selector       = exclusion.value.selector
        }
      }
      dynamic "override" {
        for_each = managed_rule.value.overrides != null ? managed_rule.value.overrides : []

        content {
          rule_group_name = override.value.rule_group_name

          dynamic "exclusion" {
            for_each = override.value.exclusions != null ? override.value.exclusions : []

            content {
              match_variable = exclusion.value.match_variable
              operator       = exclusion.value.operator
              selector       = exclusion.value.selector
            }
          }
          dynamic "rule" {
            for_each = override.value.rules != null ? override.value.rules : []

            content {
              action  = rule.value.action
              rule_id = rule.value.rule_id
              enabled = lookup(rule.value, "enabled", null)

              dynamic "exclusion" {
                for_each = rule.value.exclusions != null ? rule.value.exclusions : []

                content {
                  match_variable = exclusion.value.match_variable
                  operator       = exclusion.value.operator
                  selector       = exclusion.value.selector
                }
              }
            }
          }
        }
      }
    }
  }
}



# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_cdn_frontdoor_firewall_policy.waf_policy.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

