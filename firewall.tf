resource "azurerm_public_ip" "azure_firewall_public_ip" {
  name                = "AzureFirewall-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  name                = "AzureFirewall"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_tier            = var.firewall_sku_tier
  sku_name            = var.firewall_sku_name
  firewall_policy_id  = azurerm_firewall_policy.firewall_policy.id

  ip_configuration {
    name                 = azurerm_public_ip.azure_firewall_public_ip.name
    subnet_id            = azurerm_subnet.subnet_azure_firewall.id
    public_ip_address_id = azurerm_public_ip.azure_firewall_public_ip.id
  }
}

resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "AzureFirewallPolicy"
  resource_group_name = var.resource_group_name
  location            = var.location

}

resource "azurerm_firewall_policy_rule_collection_group" "rule_collection_group" {
  name               = "AzureFirewallPolicyRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 100

  network_rule_collection {
    name     = "NetworkRuleCollection1"
    priority = 100
    action   = "Allow"
    rule {
      name                  = "AllowOutbound"
      protocols             = ["TCP", "UDP", "ICMP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }
}
