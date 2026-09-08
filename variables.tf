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
  default = "Standard_B2s"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "employees_group_object_id" {
  type = string
}
