resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.prefix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  dns_prefix          = "aks${var.prefix}"
  node_resource_group = "MC_${var.resource_group_name}_aks-${var.prefix}"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }
}
