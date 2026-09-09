resource "azurerm_storage_account" "partage" {
  name                            = "${var.prefix}partage${random_string.uniq.result}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
}

resource "azurerm_storage_share" "partage" {
  name               = "partage-entreprise"
  storage_account_id = azurerm_storage_account.partage.id
  quota              = 50
}

resource "azurerm_role_assignment" "share_contributor" {
  scope                = azurerm_storage_account.partage.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = var.employees_group_object_id
  principal_type       = "Group"
}
