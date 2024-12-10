module "workload" {
  # ver 1.0.1
  source = "git::https://github.com/terraform-yc-modules/terraform-yc-cloud.git?ref=2a8808f"

  organization_id    = var.organization_id
  billing_account_id = var.billing_account_id

  delay_after_cloud_create = "10s"

  cloud = {
    name        = "workload"
    description = "Cloud hosting example workload."
  }

  folders = [
    {
      name        = "workload"
      description = "Contains example workload."
    }
  ]
  groups = [
    {
      name        = "workload-owner"
      description = "Workload owner group"
      cloud_roles = ["resource-manager.clouds.owner"]
      members     = var.workload_cloud_admins
    },
  ]
}

variable "workload_cloud_admins" {
  description = "Yandex IDs of Workload cloud admins"
  type        = list(string)
  default     = []
}

# ======== Assign org level roles ======= 
# Role 'group.member.admin' for the group 'workload-owner' (self-admin)
resource "yandex_organizationmanager_group_iam_member" "member_admin_for_workload" {
  group_id = module.security.groups[0].id
  role     = "organization-manager.groups.memberAdmin"
  member   = "group:${module.security.groups[0].id}"
}

# ======== Outputs =========
output "workload_cloud_id" {
  description = "ID of the cloud 'workload'"
  value       = module.workload.cloud_id
}

output "workload_cloud_name" {
  description = "Name of the cloud 'workload'"
  value       = module.workload.cloud_name
}

output "workload_cloud_folders" {
  description = "List of folders created in 'workload' cloud"
  value       = module.workload.folders
}

output "workload_cloud_groups" {
  description = "List of groups defined in 'workload' cloud and created in parent organization"
  value       = module.workload.groups
}
