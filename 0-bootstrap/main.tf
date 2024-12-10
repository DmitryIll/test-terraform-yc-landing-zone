locals {
  folder_id             = module.bootstrap.folders[0].id
  bootstrap_bucket_name = "${var.bootstrap_prefix}-${random_string.unique_id.result}"
}

resource "random_string" "unique_id" {
  length  = 4
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# Service account supposed to be used as the main subject to run org-level privileged operations (create cloud etc.)
resource "yandex_iam_service_account" "sa-tf" {
  name        = "bootstrap-sa-tf"
  description = "Service account for Terraform"
  folder_id   = local.folder_id
}

# Grant the service account the organization-manager.admin role
resource "yandex_organizationmanager_organization_iam_binding" "org_admin_for_sa_tf" {
  organization_id = var.organization_id
  role            = "organization-manager.admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-tf.id}",
  ]
}

# Grant the service account the billing.accounts.editor role
resource "yandex_organizationmanager_organization_iam_binding" "biling_editor_for_sa_tf" {
  organization_id = var.organization_id
  role            = "billing.accounts.editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-tf.id}",
  ]
}

# Grant the service account the resource-manager.admin role
resource "yandex_organizationmanager_organization_iam_binding" "resource_manager_admin_for_sa_t" {
  organization_id = var.organization_id
  role            = "resource-manager.admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-tf.id}",
  ]
}

# Grant the service account the iam.admin role
resource "yandex_organizationmanager_organization_iam_binding" "iam_admin_for_sa_t" {
  organization_id = var.organization_id
  role            = "iam.admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-tf.id}",
  ]
}

# Create an authorized access key for the service account
resource "yandex_iam_service_account_key" "sa-auth-key" {
  service_account_id = yandex_iam_service_account.sa-tf.id
  description        = "Key for service account"
  key_algorithm      = "RSA_2048"
}

# Export the key to a file (.key.json) to create a YC profile later
resource "local_file" "key" {
  content  = <<EOH
  {
    "id": "${yandex_iam_service_account_key.sa-auth-key.id}",
    "service_account_id": "${yandex_iam_service_account.sa-tf.id}",
    "created_at": "${yandex_iam_service_account_key.sa-auth-key.created_at}",
    "key_algorithm": "${yandex_iam_service_account_key.sa-auth-key.key_algorithm}",
    "public_key": ${jsonencode(yandex_iam_service_account_key.sa-auth-key.public_key)},
    "private_key": ${jsonencode(yandex_iam_service_account_key.sa-auth-key.private_key)}
  }
  EOH
  filename = ".key.json"
}
