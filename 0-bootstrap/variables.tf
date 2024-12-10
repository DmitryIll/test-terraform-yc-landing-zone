variable "organization_id" {
  description = "ID of the root organization"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID"
  type        = string
}

variable "bootstrap_prefix" {
  description = "Name pefix for buckets, service accounts, and YDB"
  type        = string
  default     = "bootstrap"
}

# Yandex ID of the root organization admins
variable "root_organization_admins" {
  description = "IDs of the root organization admins"
  type        = list(string)
}
