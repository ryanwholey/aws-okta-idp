# AWS <> Okta 

## Preconditions

Assumes that you:
* Have 2 AWS accounts, one to function as the Okta login (hub) and one to create resources to gate (spoke)
* Have a test user and group to play with in your Okta developer account

## Applying

Create the AWS roles, AWS IdP resource and the Okta AWS application

```sh
export AWS_DEFAULT_REGION=us-west-2
export TF_VAR_AWS_HUB_ACCOUNT_PROVISIONING_ROLE=arn:aws:iam::<account_id>:role/admin
export TF_VAR_AWS_SPOKE_ACCOUNT_PROVISIONING_ROLE=arn:aws:iam::<account_id>:role/admin

export TF_VAR_OKTA_ORG_NAME=<org-name>
export OKTA_API_TOKEN=<token>
export OKTA_BASE_URL=<url>

cd src
terraform init
terraform apply
```

Note the user and IdP ARN outputs

Set Okta up to query your AWS account for roles:
* Sign into your Okta organization as admin
* Locate your AWS application
* Click the "Sign On" tab in the application nav
* Click "Edit"
* Add the IdP ARN in the "Identity Provider ARN (Required only for SAML SSO)" field
* Click the "Join all roles" to allow Okta to read all roles in your account
* Hit "Save"
* Next, click the "Provisioning" tab in the application nav
* Click "Configure API Integration" > "Enable API Integration" checkbox
* Add the user "Access Key" and "Secret Key" from the terraform plan outputs
* Optionally click "Test API Credentials"
* Click "Save"
* You should land on the "Provisioning" "To App" settings page. Click "Edit" > Check the "Enable" checkbox for the "Create Users" option
* Click "Save"

Assign an Okta group to use a role queried from AWS:
* Sign into your Okta organization as admin
* Locate your AWS application
* Click the "Assignments" tab in the application nav
* Click "Assign" button dropdown > "Assign to Groups"
* Choose your test group
* Select the "developer" Role from the role dropdown
* Select the "developer" checkbox in the SAML User Roles
* Click "Save and Go Back"
* In a cognito browser, login to Okta with your test user and click on the AWS application, and you're in! You can use the "Switch Role" feature in the navigation profile dropdown menu to assume the developer role in the Spoke account

