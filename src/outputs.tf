output "okta_user" {
  value = {
    access_key_id     = aws_iam_access_key.okta_user.id
    secret_access_key = aws_iam_access_key.okta_user.secret
  }
}

output "iam_idp_arn" {
  value = aws_iam_saml_provider.okta.arn
}

output "app_id" {
  value = okta_app_saml.aws.id
}
