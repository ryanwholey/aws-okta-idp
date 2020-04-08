data "okta_group" "developers" {
  name = "developers"
}

resource "okta_app_group_assignment" "developers" {
  app_id   = data.terraform_remote_state.okta.outputs.app_id
  group_id = data.okta_group.developers.id

  profile = jsonencode({
    role = "developer"
    samlRoles = [
      "developer",
    ]
  })
}
