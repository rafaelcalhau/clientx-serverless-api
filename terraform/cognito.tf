resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.env}${title(var.service_name)}UserPool"

  email_verification_subject = "Your Verification Code"
  email_verification_message = "Please use the following code: {####}"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_uppercase = true
  }

  schema {
    name                     = "terraform"
    attribute_data_type      = "Boolean"
    mutable                  = false
    required                 = false
    developer_only_attribute = false
  }

  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = true
  }

  tags = {
    project = var.service_name
  }
}

resource "aws_cognito_user" "default_user" {
  user_pool_id             = aws_cognito_user_pool.user_pool.id
  username                 = "admin"
  desired_delivery_mediums = ["EMAIL"]
  password                 = "Admin@123"
  enabled                  = true
  message_action           = "SUPPRESS"

  attributes = {
    terraform      = true
    email          = "calhaudev@gmail.com"
    email_verified = true
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                          = "${var.env}${title(var.service_name)}UserPoolClient"
  explicit_auth_flows           = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  user_pool_id                  = aws_cognito_user_pool.user_pool.id
  id_token_validity             = 24
  prevent_user_existence_errors = "ENABLED"
}