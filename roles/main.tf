data "okta_group" "developers" {
  name = "developers"
}

resource "okta_app_group_assignment" "developers" {
  app_id   = data.terraform_remote_state.okta.outputs.app_id
  group_id = data.okta_group.developers.id

  profile = jsonencode({
    role = aws_iam_role.okta_developer.name
    samlRoles = [
      aws_iam_role.okta_developer.name
    ]
  })
}

# AWS HUB ACCOUNT 
data "aws_iam_policy_document" "allow_okta" {
  provider = aws.hub

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithSAML",
    ]
    principals {
      type        = "Federated"
      identifiers = [data.terraform_remote_state.okta.outputs.iam_idp_arn]
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
