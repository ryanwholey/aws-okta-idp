resource "okta_app_saml" "aws" {
  label                    = "aws"
  assertion_signed         = true
  audience                 = "https://signin.aws.amazon.com/saml"
  authn_context_class_ref  = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
  destination              = "https://console.aws.amazon.com/ec2/home"
  digest_algorithm         = "SHA256"
  honor_force_authn        = true
  recipient                = "https://signin.aws.amazon.com/saml"
  response_signed          = true
  signature_algorithm      = "RSA_SHA256"
  sso_url                  = "https://signin.aws.amazon.com/saml"
  subject_name_id_format   = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
  subject_name_id_template = "$${user.userName}"

  attribute_statements {
    name      = "https://aws.amazon.com/SAML/Attributes/Role"
    namespace = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri"
    type      = "EXPRESSION"
    values = [
      "arn:aws:iam::695834901730:saml-provider/Okta,arn:aws:iam::695834901730:role/developer",
      "arn:aws:iam::695834901730:saml-provider/Okta,arn:aws:iam::695834901730:role/platform",
    ]
  }

  attribute_statements {
    name      = "https://aws.amazon.com/SAML/Attributes/RoleSessionName"
    namespace = "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
    type      = "EXPRESSION"
    values = [
      "user.email",
    ]
  }

  attribute_statements {
    name      = "https://aws.amazon.com/SAML/Attributes/SessionDuration"
    namespace = "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
    type      = "EXPRESSION"
    values = [
      var.session_duration,
    ]
  }

  attribute_statements {
    name         = "groups"
    filter_type  = "REGEX"
    type         = "GROUP"
    filter_value = ".*"
  }

  lifecycle {
    ignore_changes = [groups]
  }
}

data "okta_group" "developers" {
  name = "developers"
}

resource "okta_app_group_assignment" "developers" {
  app_id   = okta_app_saml.aws.id
  group_id = data.okta_group.developers.id
}

resource "aws_iam_saml_provider" "okta" {
  name                   = "Okta"
  saml_metadata_document = okta_app_saml.aws.metadata
}


# Developer role
data "aws_iam_policy_document" "allow_idp_developer" {
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
      values   = ["https://signin.aws.amazon.com/saml"]
    }
  }
}

resource "aws_iam_role" "developer" {
  name               = "developer"
  assume_role_policy = data.aws_iam_policy_document.allow_idp_developer.json
}

data "aws_iam_policy_document" "s3_read" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_read" {
  name   = "s3_read"
  policy = data.aws_iam_policy_document.s3_read.json
}

resource "aws_iam_role_policy_attachment" "attach_s3_read" {
  policy_arn = aws_iam_policy.s3_read.arn
  role       = aws_iam_role.developer.name
}

# Platform role
data "aws_iam_policy_document" "allow_idp_platform" {
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
      values   = ["https://signin.aws.amazon.com/saml"]
    }
  }
}

resource "aws_iam_role" "platform" {
  name               = "platform"
  assume_role_policy = data.aws_iam_policy_document.allow_idp_platform.json
}

data "aws_iam_policy_document" "full" {
  statement {
    effect = "Allow"
    actions = [
      "*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "full" {
  name   = "full"
  policy = data.aws_iam_policy_document.full.json
}

resource "aws_iam_role_policy_attachment" "attach_full" {
  policy_arn = aws_iam_policy.full.arn
  role       = aws_iam_role.platform.name
}
