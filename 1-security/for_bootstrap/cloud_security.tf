module "security" {
  # ver 1.0.1
  source = "git::https://github.com/terraform-yc-modules/terraform-yc-cloud.git?ref=2a8808f"

  organization_id    = var.organization_id
  billing_account_id = var.billing_account_id

  delay_after_cloud_create = "10s"

  cloud = {
    name        = "security"
    description = "Cloud hosting security related services"
  }

  folders = [
    {
      name        = "audit"
      description = "Contains audit trails of your infrastructure."
    },
  ]

  groups = [
    {
      name        = "security"
      description = "Security admin group"
      cloud_roles = ["resource-manager.clouds.owner"]
      members     = var.security_cloud_admins
    },
    {
      name        = "auditors"
      description = "Auditors group"
    },
  ]
}

# ======== Assign org level roles ======= 
# Role 'auditor' for the organization
resource "yandex_organizationmanager_organization_iam_binding" "org_auditor" {
  organization_id = var.organization_id
  role            = "auditor"
  members = [
    "group:${module.security.groups[1].id}",
  ]
}

# Role 'group.member.admin' for the group 'security' (self-admin)
resource "yandex_organizationmanager_group_iam_member" "member_admin_for_security" {
  group_id = module.security.groups[0].id
  role     = "organization-manager.groups.memberAdmin"
  member   = "group:${module.security.groups[0].id}"
}

# Role 'group.member.admin' for the group 'auditors' 
resource "yandex_organizationmanager_group_iam_member" "member_admin_for_auditors" {
  group_id = module.security.groups[1].id
  role     = "organization-manager.groups.memberAdmin"
  member   = "group:${module.security.groups[0].id}"
}

# ======== Service Account for Audit Trails ========
# Roles: 
#   "audit-trails.viewer" for Org, 
resource "yandex_iam_service_account" "audit_trails_sa" {
  folder_id   = module.security.folders[0].id
  name        = "audit-trails-sa"
  description = "Service account for configuring Audit Trails"
}

# Роль "audit-trails.viewer" для SA для сбора трейлов аудита со всей организации
resource "yandex_organizationmanager_organization_iam_binding" "audit-admin-trails" {
  organization_id = var.organization_id
  role            = "audit-trails.viewer"
  members = [
    "serviceAccount:${yandex_iam_service_account.audit_trails_sa.id}",
  ]
}

variable "security_cloud_admins" {
  description = "Yandex IDs of Securty cloud admins"
  type        = list(string)
  default     = []
}

##############################
output "security_cloud_id" {
  description = "ID of the cloud 'security'"
  value       = module.security.cloud_id
}

output "security_cloud_name" {
  description = "Name of the cloud 'security'"
  value       = module.security.cloud_name
}

output "security_cloud_folders" {
  description = "List of folders created in 'security' cloud"
  value       = module.security.folders
}

output "security_cloud_groups" {
  description = "List of groups defined in 'security' cloud and created in parent organization"
  value       = module.security.groups
}

output "audit_trails_sa" {
  description = "Service Account for Audit Trails"
  value       = yandex_iam_service_account.audit_trails_sa.id
}
