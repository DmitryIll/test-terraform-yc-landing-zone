module "bootstrap" {
  # ver 1.0.1
  source = "git::https://github.com/terraform-yc-modules/terraform-yc-cloud.git?ref=2a8808f"

  organization_id    = var.organization_id
  billing_account_id = var.billing_account_id


  delay_after_cloud_create = "10s"

  cloud = {
    name        = "bootstrap"
    description = "Cloud hosting basic resources for TF state, CICD and deploying workload clouds."
  }

  folders = [
    {
      name        = "iac"
      description = "Contains TF state bucket and locks table for IAC state."
    }
  ]
  groups = [
    { # Org admin - roles : organization.admin
      name        = "org-admin"
      description = "Organization admin group"
      members     = var.root_organization_admins
    },
  ]
}

# ======== Assign org level roles ======= 
resource "yandex_organizationmanager_organization_iam_binding" "org_admin_for_org_admin" {
  organization_id = var.organization_id
  role            = "organization-manager.admin"
  members = [
    "group:${module.bootstrap.groups[0].id}",
  ]
}
