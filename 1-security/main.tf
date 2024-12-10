# Getting service account for Audit Trails  
data "yandex_iam_service_account" "audit_trails_sa" {
  # this SA name is hardcoded in coud_security.tf
  # alternatively one could use remote state datasource
  name      = "audit-trails-sa"
  folder_id = var.folder_id
}

module "audit_trails" {
  source = "git::https://github.com/terraform-yc-modules/terraform-yc-audit-trails.git?ref=1.0.1"

  folder_id          = var.folder_id
  name               = "org-trail"
  description        = "Audit trail for the entire organization"
  service_account_id = data.yandex_iam_service_account.audit_trails_sa.service_account_id

  # destination type for storing logs
  destination_type = "storage" # ["storage", "logging", "data_stream"]

  # object_prefix      = "org-trail"

  # filters applied to control-plane events
  management_events_filter = [
    {
      resource_id   = var.organization_id
      resource_type = "organization-manager.organization"
    }
  ]

  # # filters applied to data-plane events
  # # IMPORTANT: collection and storage of data-plane events might be billale (see documenation)
  # data_events_filter = [
  #   {
  #     service       = "kms"
  #     resource_id   = var.folder_id
  #     resource_type = "resource-manager.folder"
  #   }
  # ]
}
