resource "azurerm_databricks_workspace" "databricks_workspace" {
  name                        = "databricks-se-poc"
  location                    = azurerm_resource_group.resource_group.location
  resource_group_name         = azurerm_resource_group.resource_group.name
  sku                         = var.databricks_workspace_sku
  managed_resource_group_name = "databricks-managed-${var.resource_group_name}"

  public_network_access_enabled         = true
  network_security_group_rules_required = "AllRules"

  custom_parameters {
    no_public_ip        = true
    public_subnet_name  = azurerm_subnet.subnet_public.name
    private_subnet_name = azurerm_subnet.subnet_private.name
    virtual_network_id  = azurerm_virtual_network.virtual_network_databricks.id

    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.association_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.association_private.id

  }
}