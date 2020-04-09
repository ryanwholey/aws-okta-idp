provider "aws" {
  assume_role {
    role_arn = var.AWS_HUB_PROVISIONING_ROLE
  }
}

provider "okta" {
  org_name = var.OKTA_ORG_NAME
}
