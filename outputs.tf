output "resource" {
  description = "This is the full output for the resource."
  value       = azurerm_cdn_frontdoor_firewall_policy.waf_policy
}

output "resource_id" {
  description = "The ID of the WAF Policy."
  value       = azurerm_cdn_frontdoor_firewall_policy.waf_policy.id
}
