output "kv_name" { value = azurerm_key_vault.kv.name }
output "bdd_client_id" { value = azurerm_user_assigned_identity.bdd.client_id }
output "tenant_id" { value = data.azurerm_client_config.current.tenant_id }
output "storage_partage_name" { value = azurerm_storage_account.partage.name }
