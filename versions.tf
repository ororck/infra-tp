terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = "~> 4.0" }
    random     = { source = "hashicorp/random", version = "~> 3.6" }
    helm       = { source = "hashicorp/helm", version = "~> 3.3" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.2" }
  }

  backend "azurerm" {
    resource_group_name  = "msaidiRG"
    storage_account_name = "sttpmohtfstate31884"
    container_name       = "tfstate"
    key                  = "infra.tfstate"
    use_azuread_auth     = true
    use_oidc             = true
  }
}
