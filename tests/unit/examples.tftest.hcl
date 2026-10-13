mock_provider "azapi" {}

mock_provider "azuread" {
  mock_data "azuread_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000001"
    }
  }
}

mock_provider "azurerm" {
  mock_resource "azurerm_cdn_frontdoor_firewall_policy" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/frontDoorWebApplicationFirewallPolicies/example"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
}

run "default_example" {
  command = apply

  module {
    source = "./examples/default"
  }

  assert {
    condition     = module.test.resource.mode == "Prevention" && module.test.resource.sku_name == "Premium_AzureFrontDoor"
    error_message = "The default example must preserve its prevention mode and Premium Front Door SKU."
  }

  assert {
    condition     = module.test.resource.resource_group_name == azurerm_resource_group.this.name && module.test.resource_id != ""
    error_message = "The default example must create its policy in the example resource group and expose its resource ID."
  }
}

run "custom_rules_example" {
  command = apply

  module {
    source = "./examples/waf_with_custom_rules"
  }

  assert {
    condition     = length(module.test.resource.custom_rule) == 3
    error_message = "The custom-rules example must retain all three custom rules."
  }

  assert {
    condition     = module.test.resource.custom_block_response_status_code == 405 && module.test.resource.custom_block_response_body == base64encode("Blocked by Azure WAF")
    error_message = "The custom-rules example must preserve its custom block response."
  }
}

run "custom_and_managed_rules_example" {
  command = apply

  module {
    source = "./examples/waf_with_custom_managed_rules"
  }

  assert {
    condition     = length(module.test.resource.custom_rule) == 3 && length(module.test.resource.managed_rule) == 2
    error_message = "The managed-rules example must retain its three custom rules and two managed rule sets."
  }

  assert {
    condition     = module.test.resource.resource_group_name == azurerm_resource_group.this.name && module.test.resource.custom_block_response_status_code == 405
    error_message = "The managed-rules example must preserve its resource-group wiring and custom block response."
  }
}
