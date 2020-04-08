# OKTA
resource "okta_app_saml" "aws" {
  label             = "AWS"
  preconfigured_app = "amazon_aws"

  features = [
    "PUSH_NEW_USERS",
  ]

  lifecycle {
    ignore_changes = [groups]
  }
}

# OKTA AWS
data "aws_iam_policy_document" "okta_user" {
  provider = aws.hub

  # https://help.okta.com/en/prod/Content/Topics/DeploymentGuides/AWS/connect-okta-single-aws.htm
  statement {
    effect = "Allow"
    actions = [
      "iam:ListRoles",
      "iam:ListAccountAliases",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "okta_user" {
  provider = aws.hub

  name = "okta-read-roles"
  user = aws_iam_user.okta_user.name

  policy = data.aws_iam_policy_document.okta_user.json
}

resource "aws_iam_user" "okta_user" {
  provider = aws.hub

  name = "Okta"
}

resource "aws_iam_access_key" "okta_user" {
  provider = aws.hub

  user = aws_iam_user.okta_user.name
}

resource "aws_iam_saml_provider" "okta" {
  provider = aws.hub

  name                   = "Okta"
  saml_metadata_document = okta_app_saml.aws.metadata
}
