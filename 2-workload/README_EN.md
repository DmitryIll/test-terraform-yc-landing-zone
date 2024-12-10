# Creating a Workload Cloud (2-workload)

The task of this module is to demonstrate an example of creating and operating a "general purpose" cloud `workload` using modules from the [module library](https://github.com/terraform-yc-modules).

## Prerequisites

- Cloud `bootstrap` must be deployed and configured.

## Step-by-Step Instructions

> [!WARNING] Attention
> Some esources created in this example are billable.

### Creating the `workload` Cloud

> Following command are executed in the `0-bootstrap` directory, with the YC CLI profile set for a user with `resource-manager.admin` rights at the organization level.

- [ ] Copy the cloud description file `../2-workload/for_bootstrap/cloud_workload.tf` to the `0-bootstrap` directory

```sh
cp ../2-workload/for_bootstrap/cloud_workload.tf .
```

- [ ] Initialize the variable `workload_cloud_admins` - this is a list of accounts (Yandex IDs) of future administrators of the `workload` cloud. They will be added to the `workload-owner` group, which is assigned the role `resource-manager.clouds.owner` on the `workload` cloud.

- You can set the value in the `terraform.tfvars` file in the `0-bootstrap` directory (at this stage we are working with the configuration in the `0-bootstrap` directory) or through the environment variable `TF_VAR_workload_cloud_admins`.

- [ ] Reinitialize the Terraform provider. This is necessary in case if any providers not downloaded yet will be used in the `workload` cloud configuration.

```sh
terraform init
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

- [ ] From the output, copy the values of `workload_cloud_id` and `id` of the `workload` folder (from the list of `workload_cloud_folders`) which will be needed at the stage of filling the cloud.

> Technically, you have supplemented the configuration in `0-bootstrap` with a description of the `workload` cloud without filling it, installed any missing providers, and applied the configuration on behalf of a subject with `resource-manager.admin` rights.

After applying this configuration, the following will be created in your organization:

- **Cloud** `workload`, **folder** `workload`;

- **Group** `workload-owner` with roles:
  - `resource-manager.clouds.owner` on the `workload` cloud,
  - `organization-manager.groups.memberAdmin` on itself - allowing adding new subjects without involving organization administrators.

- The specified users are added to the group `workload-owner`.

### Operating the `workload` cloud

> Following command are executed in the `2-workload` directory, with the YC CLI profile set for a user or service account with rights of `resource-manager.clouds.owner` on the `workload` cloud.

- [ ] Initialize Terraform provider in the `2-workload` directory

```sh
terraform init --upgrade
```

- [ ] In the file `terraform.tfvars`, fill in values for variables `cloud_id` and `folder_id` with values obtained from creating the `workload` cloud.

- [ ] Optionally, you can modify resources described in file `main.tf`.

- [ ] Validate configuration and execution plan. This helps identify possible errors before actual application.

```sh
terraform validate
terraform plan
```

> You can modify contents of directory `2-workload`, adding or removing resources as you see fit. Everything described in file `main.tf` is an example for filling out the workload cloud.

- [ ] Apply configuration from the directory `2-workload`.

```sh
terraform apply
```

After applying this configuration the following will be created in the `workload` cloud:

- Network
- Kubernetes Cluster
- PostgreSQL Cluster
- Auxiliary resources created automatically

### Deleting the Workload Cloud

Act in reverse order.

1. In the directory `2-workload`, from a user who is a member of group `workload-owner`, execute:

```sh
terraform destroy
```

Review proposed actions, confirm your intention to delete resources (type `yes`). This will delete all contents of workload cloud.

2. In directory `0-bootstrap`, delete file `cloud_workload.tf`.

3. In directory `0-bootstrap`, from a user with rights of `resource-manager.admin`, execute:

```sh
terraform apply
```

> [!WARNING] Important
> The last command is specifically `terraform apply`, not `terraform destroy`, because the `workload` cloud will be deleted as result of Terraform bringing physical configuration in line with definitions in the `0-bootstrap` directory, where there is no longer a file describing `workload` cloud. If you execute `terraform destroy`, all configurations will be deleted, including `bootstrap` cloud and all other clouds created similarly.

Review proposed actions, confirm your intention to delete resources (type `yes`). This will delete both workload cloud (along with all remaining resources) and group `workload-owner`.
