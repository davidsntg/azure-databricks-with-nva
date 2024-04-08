resource "azurerm_virtual_network" "virtual_network_hub" {
  name                = "hub-vnet"
  address_space       = ["10.100.0.0/24"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnet_azure_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network_hub.name
  address_prefixes     = ["10.100.0.0/25"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
}

resource "azurerm_virtual_network" "virtual_network_databricks" {
  name                = "databricks-vnet"
  address_space       = ["10.200.0.0/24"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnet_public" {
  name                 = "public-snet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network_databricks.name
  address_prefixes     = ["10.200.0.0/25"]

  delegation {
    name = "databricks-subnet-public-delegation"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet" "subnet_private" {
  name                 = "private-snet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network_databricks.name
  address_prefixes     = ["10.200.0.128/25"]

  delegation {
    name = "databricks-subnet-private-delegation"

    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_route_table" "route_databricks_private" {
  name                          = "databricks-private-rt"
  location                      = azurerm_resource_group.resource_group.location
  resource_group_name           = azurerm_resource_group.resource_group.name
  disable_bgp_route_propagation = true

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }

  route {
    name           = "AzureDatabricks_Direct"
    address_prefix = "AzureDatabricks"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "association_private" {
  subnet_id      = azurerm_subnet.subnet_private.id
  route_table_id = azurerm_route_table.route_databricks_private.id
}

resource "azurerm_virtual_network_peering" "hub-to-databricks" {
  name                      = "hub-to-databricks"
  resource_group_name       = azurerm_resource_group.resource_group.name
  virtual_network_name      = azurerm_virtual_network.virtual_network_hub.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network_databricks.id
}

resource "azurerm_virtual_network_peering" "databricks-to-hub" {
  name                      = "databricks-to-hub"
  resource_group_name       = azurerm_resource_group.resource_group.name
  virtual_network_name      = azurerm_virtual_network.virtual_network_databricks.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network_hub.id
}


resource "azurerm_network_security_group" "network_security_group" {
  name                = "databricks-nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "association_public" {
  subnet_id                 = azurerm_subnet.subnet_public.id
  network_security_group_id = azurerm_network_security_group.network_security_group.id
}

resource "azurerm_subnet_network_security_group_association" "association_private" {
  subnet_id                 = azurerm_subnet.subnet_private.id
  network_security_group_id = azurerm_network_security_group.network_security_group.id
}