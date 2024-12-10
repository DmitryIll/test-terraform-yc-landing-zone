# Deploying cloud to host org-level information security measures (1-security)

The main task of this step is to create a cloud for hosting the resources and services necessary for implementing information security measures.

> From a general approach perspective, the "security" cloud is also considered a workload; however, it is described separately to demonstrate the recommended set of services and applicable settings.

## Prerequisites

- Cloud `bootstrap` must be deployed and configured.

## Step-by-Step Instructions

### Creating the `security` Cloud

> Following commands should be executed in the `0-bootstrap` directory, with the YC CLI profile set for a user with `resource-manager.admin` rights at the organization level.

- [ ] Copy the cloud description file `../1-security/for_bootstrap/cloud_security.tf` to the `0-bootstrap` directory

```sh
cp ../1-security/for_bootstrap/cloud_security.tf .
```

- [ ] Initialize the variable `security_cloud_admins` - this is a list of accounts (Yandex IDs) of future administrators of the `security` cloud. They will be added to the `security` group, which is assigned the role of `resource-manager.clouds.owner` for the `security` cloud.

- You can set the value in the `terraform.tfvars` file in the `0-bootstrap` directory (at this stage we are working with the configuration in the `0-bootstrap` directory) or through the environment variable `TF_VAR_security_cloud_admins`.

- [ ] Reinitialize the Terraform provider. This is necessary in case if any providers not downloaded yet will be used in the `security` cloud configuration.

```sh
terraform init --upgrade
```

- [ ] Validate the configuration and the execution plan. This helps identify possible errors before actual application.

```sh
terraform validate
terraform plan
```

- [ ] Apply the configuration from the `0-bootstrap` directory

```sh
terraform apply
```

- [ ] From the output, copy the values of `security_cloud_id` and `id` of the `audit` folder (from the list of `security_cloud_folders`) which will be needed at the stage of filling the cloud.

> Technically, you have supplemented the configuration in `0-bootstrap` with a description of the `security` cloud without filling it, installed any missing providers, and applied the configuration on behalf of a subject with `resource-manager.admin` rights.

After applying this configuration, the following will be created in your organization:

- **Cloud** `security`, containing **folder** `audit`;

- **Group** `security` assigned roles of:
  - `resource-manager.clouds.owner` on the `security` cloud,
  - `organization-manager.groups.memberAdmin` on itself and on the group `auditors`, allowing adding new subjects without involving organization administrators.

- Use this group to include passport or federated accounts of information security administrators.

- **Group** `auditors` with role `auditor` for the entire organization. Use this group to include passport or federated accounts of auditors (view-only access without modification rights for all cloud resources).

- **Service Account** `audit-trails-sa` with roles of `audit-trails.viewer` for the entire organization for collecting audit trails.

- The specified users are added to the group `security`.

### Operating the `security` Cloud

> Following commands should be executed in the `1-security` directory, with the YC CLI profile set for a user or service account with rights of `resource-manager.clouds.owner` on the `security` cloud.

- [ ] Initialize Terraform provider in the `1-security` directory

```sh
terraform init --upgrade
```

- [ ] In the file `terraform.tfvars`, fill in values for variables `cloud_id` and `folder_id` with values obtained from creating the `security` cloud.

- [ ] Optionally, you can modify Audit Trails configuration described in the file `main.tf`.

- Set:
  - `destination_type`: type of storage for saving audit trails.
  - `management_events_filter`: filter for management-level events that will be saved in audit trails.
  - `data_events_filter`: filter for data-level events that will be saved in audit trails.

- [ ] Validate configuration and execution plan. This helps identify possible errors before actual application.

```sh
terraform validate
terraform plan
```

- [ ] Apply configuration from the `1-security` directory.

```sh
terraform apply
```

After applying this configuration in cloud `security` in folder `audit`, there will be created:

- **Bucket** `audit-****` (where **** are 4 random characters ensuring unique bucket naming) for storing audit trails.

- **Audit Trail** named `org-trail`, configured to collect configuration-level events from all organization resources and save them in object storage (default configuration is described in file `main.tf`).
