data "terraform_remote_state" "okta" {
  backend = "local"

  config = {
    path = "../src/terraform.tfstate"
  }
}
