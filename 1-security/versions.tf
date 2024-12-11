terraform {
  required_version = ">= 1.3.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.134"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "> 5.44"
    }

    random = {
      source  = "hashicorp/random"
      version = "> 3.5"
    }
  }
}

provider "aws" {
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}
