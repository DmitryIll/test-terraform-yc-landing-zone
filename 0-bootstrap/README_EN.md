# Creating Basic Infrastructure (0-bootstrap)

The main task of this step is to create basic infrastructure for deploying cloud environments, managing access, and implementing the Infrastructure-as-Code approach.

## Prerequisites
- Organization ID;
- Payment account ID;
- Installed YC CLI command-line utility with a configured profile;
- The account under which this step will be executed must have the following roles:
  - `organization-manager.organizations.owner` - organization owner 
  
  or

  - `resource-manager.admin` at the organization level (to create, edit, and delete clouds and directories, as well as manage access to them);
  - `billing.accounts.editor` on the payment account (to bind clouds and services to the payment account).

## Step-by-Step Instructions
### Initialize Terraform and Apply Configuration
- [ ] Initialize Terraform in the `0-bootstrap` directory

```sh
terraform init
```

- [ ] Create a file named `terraform.tfvars` in the `0-bootstrap` directory and set the input parameter values

```sh
organization_id          = "YOUR_CLOUD_ORGANIZATION_ID"
billing_account_id       = "YOUR_PAYMENT_ACCOUNT_ID"
root_organization_admins = [ "YANDEX_ID_ADMIN", "YANDEX_ID...", ... ]
```

- [ ] Validate the configuration and check the planned execution. This helps identify possible errors before actual application

```sh
terraform validate
terraform plan
```

- [ ] Apply the configuration from the `0-bootstrap` directory

```sh
terraform apply
```

### Create and Configure YC Profile
After successfully applying the configuration, several files will be created in the `0-bootstrap` directory to configure the `YC` utility profile.
- To create a profile, use the script `.create-profile-SERVICE_ACCOUNT_NAME.sh`. You can edit and run it manually if necessary. To create a profile in the terminal, execute:

```sh
./.create-profile-SERVICE_ACCOUNT_NAME.sh
```

A message will be displayed:  
`Profile 'SERVICE_ACCOUNT_NAME' created and activated.`

- To activate the profile and set environment variables, use `.activate-profile-SERVICE_ACCOUNT_NAME.sh`. This can also be edited if needed. To activate the profile in the terminal, execute: 

```sh
source ./.activate-profile-SERVICE_ACCOUNT_NAME.sh
```
A message will be displayed: `Profile 'SERVICE_ACCOUNT_NAME' activated.`

> Important: 
> 1. Execute the command `source ...`, as mentioned above, each time you plan to apply configurations with organization-level privileges.  
> 2. The IAM token lifespan for a service account is no more than 12 hours; it needs to be periodically refreshed. For this, regularly execute `source ...`.

### Transfer Terraform State to Object Storage (optional)
  - Obtain the value of the output parameter `backend_tf` using the command:
```sh
terraform output backend_tf
```
Result:
```js
<<EOT
terraform {
  backend "s3" {
    region         = "ru-central1"
    bucket         = "bootstrap-****"   # **** will be random characters
    key            = "bootstrap"

    dynamodb_table = "state-lock-table"

    endpoints = {
      s3       = "https://storage.yandexcloud.net",
      dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/****/****"  # **** will be your connection parameters
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
EOT
```
  - Create a file named `backend.tf` in the `0-bootstrap` directory and paste the text between lines tagged with `EOT` (do not copy lines with `EOT`).
  - Initialize environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` with values from the created `.env` file:
```sh
source ./.env
```
Or, if you are using a service account with a dedicated `YC` profile, execute:
```sh
source ./.activate-profile-SERVICE_ACCOUNT_NAME.sh
```
  - Migrate Terraform state

```sh
terraform init -migrate-state
```

When prompted with `Do you want to copy existing state to the new backend?`, type `yes` (or use an additional flag `-auto-approve` in the command line).

## Results of Application
After applying the configuration, the following will be created in your organization:
- **Group** `org-admin` with role `organization-manager.admin` for the entire organization. This group contains Yandex ID specified in the parameter `root_organization_admins`. Use this group to include Yandex IDs or federated accounts of global administrators.
- **Cloud** `bootstrap` and **folder** `iac`, containing:
  - **Bucket** `bootstrap-****` for storing Terraform state (**** will be 4 random characters for unique bucket naming).
  - **Service Account** `bootstrap-terraform-sa` granted roles of `organization-manager.admin` for the entire organization and `storage.admin` for the folder `iac`.
    
    You can use this account to configure CICD tools.

    The static key of this account, necessary for initializing environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, is saved in a local file `.env`. When using external CICD, configure environment variable initialization with values from `.env`.
