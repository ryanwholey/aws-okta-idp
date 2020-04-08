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

  user     = aws_iam_user.okta_user.name
}

# AWS HUB ACCOUNT 
resource "aws_iam_saml_provider" "okta" {
  provider = aws.hub

  name                   = "Okta"
  saml_metadata_document = okta_app_saml.aws.metadata
}

data "aws_iam_policy_document" "allow_okta" {
  provider = aws.hub

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithSAML",
    ]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_saml_provider.okta.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "SAML:aud"

      values = [
        "https://signin.aws.amazon.com/saml",
      ]
    }
  }
}

resource "aws_iam_role" "okta_developer" {
  provider = aws.hub

  name               = "developer"
  assume_role_policy = data.aws_iam_policy_document.allow_okta.json
}

data "aws_iam_policy_document" "allow_assume_developer" {
  provider = aws.hub

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      aws_iam_role.developer.arn
    ]
  }
}

resource "aws_iam_policy" "allow_assume_developer" {
  provider = aws.hub

  name   = "allow_assume_developer"
  policy = data.aws_iam_policy_document.allow_assume_developer.json
}

resource "aws_iam_role_policy_attachment" "okta_attach" {
  provider = aws.hub

  policy_arn = aws_iam_policy.allow_assume_developer.arn
  role       = aws_iam_role.okta_developer.name
}

# AWS SPOKE ACCOUNT
data "aws_caller_identity" "current" {
  provider = aws.hub
}

data "aws_iam_policy_document" "assume" {
  provider = aws.spoke

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "developer" {
  provider = aws.spoke

  name               = "developer"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "developer" {
  provider = aws.spoke

  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "developer" {
  provider = aws.spoke

  name   = "developer"
  policy = data.aws_iam_policy_document.developer.json
}

resource "aws_iam_role_policy_attachment" "developer" {
  provider = aws.spoke

  role       = aws_iam_role.developer.name
  policy_arn = aws_iam_policy.developer.arn
}

resource "aws_s3_bucket" "bucket" {
  provider = aws.spoke

  bucket = "${var.OKTA_ORG_NAME}-okta-aws-test"
  acl    = "private"
}

resource "aws_s3_bucket_object" "test" {
  provider = aws.spoke

  bucket  = aws_s3_bucket.bucket.id
  key     = "test"
  content = "hello human"
}
