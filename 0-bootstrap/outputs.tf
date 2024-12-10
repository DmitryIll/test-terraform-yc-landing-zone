output "bootstrap_cloud_id" {
  description = "ID of the cloud 'bootstrap'"
  value       = module.bootstrap.cloud_id
}

output "bootstrap_cloud_name" {
  description = "Name of the cloud 'bootstrap'"
  value       = module.bootstrap.cloud_name
}

output "bootstrap_cloud_folders" {
  description = "List of folders created in 'bootstrap' cloud"
  value       = module.bootstrap.folders
}

output "bootstrap_cloud_groups" {
  description = "List of groups defined in 'bootstrap' cloud and created in parent organization"
  value       = module.bootstrap.groups
}

output "bootstrap_service_account_id" {
  description = "Bootstrap service account ID"
  value       = yandex_iam_service_account.sa-tf.id
}
