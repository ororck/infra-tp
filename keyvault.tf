resource "random_password" "pg" {
  length           = 24
  special          = true
  override_special = "!#%*-_"
}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-${var.prefix}-${random_string.uniq.result}"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
}

resource "azurerm_role_assignment" "kv_admin_me" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# La pipeline CI/CD (id-tp-cicd) doit pouvoir lire/écrire ce secret elle-même :
# data.azurerm_client_config.current pointe vers l'identité qui exécute Terraform
# à l'instant T (moi en local, id-tp-cicd en CI). Sans cette attribution statique,
# le premier apply en CI échoue en 403 avant même de pouvoir remplacer kv_admin_me,
# faute d'accès pour rafraîchir l'état du secret.
data "azurerm_user_assigned_identity" "cicd" {
  name                = "id-tp-cicd"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "kv_admin_cicd" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_user_assigned_identity.cicd.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_key_vault_secret" "pg" {
  name         = "postgres-password"
  value        = random_password.pg.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_admin_me, azurerm_role_assignment.kv_admin_cicd]
}

resource "azurerm_user_assigned_identity" "bdd" {
  name                = "id-tp-bdd"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "kv_reader_bdd" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.bdd.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_federated_identity_credential" "bdd" {
  name                = "fc-sa-postgres"
  resource_group_name = data.azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.bdd.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:bdd:sa-postgres"
}
