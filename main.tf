data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

resource "random_string" "uniq" {
  length  = 6
  special = false
  upper   = false
}
