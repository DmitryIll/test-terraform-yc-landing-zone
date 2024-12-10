# Grant the service account the storage.admin role
resource "yandex_resourcemanager_folder_iam_member" "sa-tf-admin-s3" {
  folder_id = local.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa-tf.id}"
}

# Grant the service account the kms.editor role
resource "yandex_resourcemanager_folder_iam_member" "sa-tf-editor-kms" {
  folder_id = local.folder_id
  role      = "kms.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-tf.id}"
}

# Grant the service account the ydb.editor role
resource "yandex_resourcemanager_folder_iam_member" "sa-tf-editor-ydb" {
  folder_id = local.folder_id
  role      = "ydb.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-tf.id}"
}

# Create a static access key
resource "yandex_iam_service_account_static_access_key" "sa-tf-static-key" {
  service_account_id = yandex_iam_service_account.sa-tf.id
  description        = "Static access key for bucket ${local.bootstrap_bucket_name} and YDB"
}

module "state_bucket" {
  source      = "git::https://github.com/terraform-yc-modules/terraform-yc-s3.git?ref=1.0.4"
  bucket_name = local.bootstrap_bucket_name
  folder_id   = local.folder_id
  versioning = {
    enabled = true
  }
  server_side_encryption_configuration = {
    enabled = true
  }
  lifecycle_rule = [{
    enabled = true
    noncurrent_version_expiration = {
      days = 60
    }
  }]

}

# Create a YDB database for the state file lock
resource "yandex_ydb_database_serverless" "database" {
  name      = "${var.bootstrap_prefix}-ydb"
  folder_id = local.folder_id
}

# Wait 60 sec after YDB creation
resource "time_sleep" "wait_for_database" {
  create_duration = "60s"
  depends_on      = [yandex_ydb_database_serverless.database]
}

# Create a table in YDB for the state file lock
resource "aws_dynamodb_table" "lock_table" {
  name         = "state-lock-table"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
  depends_on = [time_sleep.wait_for_database, yandex_resourcemanager_folder_iam_member.sa-tf-editor-ydb, yandex_iam_service_account_static_access_key.sa-tf-static-key]
}

# Create a .env file with access keys
resource "local_file" "env" {
  content  = <<EOF
export AWS_ACCESS_KEY_ID="${yandex_iam_service_account_static_access_key.sa-tf-static-key.access_key}"
export AWS_SECRET_ACCESS_KEY="${yandex_iam_service_account_static_access_key.sa-tf-static-key.secret_key}"
EOF
  filename = ".env"
}

# Script .create-profile-<service_account_name>.sh to create a YC profile for service account
resource "local_file" "create_yc_profile" {
  content  = <<EOF
#!/bin/bash
yc config profile create ${yandex_iam_service_account.sa-tf.name}
yc config set organization-id ${var.organization_id}
yc config set cloud-id ${module.bootstrap.cloud_id}
yc config set folder-id ${module.bootstrap.folders[0].id}
yc config set service-account-key .key.json
EOF
  filename = ".create-profile-${yandex_iam_service_account.sa-tf.name}.sh"
}

# Script .activate-profile-<service_account_name>.sh to activate YC profile for service account
resource "local_file" "activate_yc_profile" {
  content  = <<EOF
yc config profile activate ${yandex_iam_service_account.sa-tf.name}
export YC_TOKEN=$(yc iam create-token)
export IAM_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
source .env
EOF
  filename = ".activate-profile-${yandex_iam_service_account.sa-tf.name}.sh"
}

# Instructions regarding how to migrate to remote Terraform state
output "backend_tf_textnote" {
  value = <<EOF
***************
To migrate to remote Terraform state follow this steps:
1. From the output `backend_tf` copy all text between EOH tags and paste into new `backend.tf` file.
2. Initialize environment variables from `.env` file (`source ./.env`).
3. Run `terraform init -migrate-state` to migrate to remote state.

Optionally:
- to create and configure new YC profile for service account `${yandex_iam_service_account.sa-tf.name}` execute:
  ./.create-profile-${yandex_iam_service_account.sa-tf.name}.sh
  source ./.activate-profile-${yandex_iam_service_account.sa-tf.name}.sh
***************
EOF
}

# Remote backend configuration file content
output "backend_tf" {
  description = "Remote backend configuration file content.  (see README.md for details)"
  value       = <<EOF
terraform {
  backend "s3" {
    region         = "ru-central1"
    bucket         = "${module.state_bucket.bucket_name}"
    key            = "${var.bootstrap_prefix}"

    dynamodb_table = "${aws_dynamodb_table.lock_table.id}"

    endpoints = {
      s3       = "https://storage.yandexcloud.net",
      dynamodb = "${yandex_ydb_database_serverless.database.document_api_endpoint}"
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
EOF
}
