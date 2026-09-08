variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type    = string
  default = "msaidiRG"
}

variable "prefix" {
  type    = string
  default = "tpmoh"
}

variable "node_vm_size" {
  type    = string
  default = "Standard_D2_v3"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "employees_group_object_id" {
  type = string
}

variable "operator_object_id" {
  type        = string
  description = "Object ID Entra de l'opérateur humain (moi), pour l'accès Key Vault local. Indépendant de qui exécute Terraform."
}
