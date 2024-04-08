variable "location" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  type    = string
  default = "rg-databricks-se"
}

variable "username" {
  type    = string
  default = "adminazure"
}

variable "databricks_workspace_sku" {
  type    = string
  default = "premium"
}

variable "firewall_sku_name" {
  type    = string
  default = "AZFW_VNet"
}

variable "firewall_sku_tier" {
  type    = string
  default = "Standard"
}