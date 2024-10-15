# resource "azurerm_role_assignment" "this" {
#   for_each = var.role_assignments

#   principal_id                           = each.value.principal_id
#   scope                                  = azurerm_resource_group.TODO.id # TODO: Replace this dummy resource azurerm_resource_group.TODO with your module resource
#   condition                              = each.value.condition
#   condition_version                      = each.value.condition_version
#   delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
#   role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
#   role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
#   skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
# }


resource "azurerm_role_assignment" "this_virtual_machine" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_cdn_frontdoor_firewall_policy.waf_policy.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  description                            = each.value.description
  principal_type                         = each.value.principal_type
  role_definition_id                     = (length(split("/", each.value.role_definition_id_or_name))) > 3 ? each.value.role_definition_id_or_name : null
  role_definition_name                   = (length(split("/", each.value.role_definition_id_or_name))) > 3 ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
