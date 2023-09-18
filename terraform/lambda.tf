data "archive_file" "authorizer" {
  output_path = "files/apiAuthorizer.zip"
  source_file = "${local.lambdas_path}/apiAuthorizer.js"
  type        = "zip"
}

data "archive_file" "auth_login" {
  output_path = "files/auth_login.zip"
  source_file = "${local.lambdas_path}/auth/login.js"
  type        = "zip"
}

data "archive_file" "clients" {
  for_each = local.lambdas.clients

  output_path = "files/clients${each.key}.zip"
  source_file = "${local.lambdas_path}/clients/${each.key}.js"
  type        = "zip"
}

data "archive_file" "verify_access_token" {
  output_path = "files/verify_access_token.zip"
  source_file = "${local.lambdas_path}/auth/verifyAccessToken.js"
  type        = "zip"
}

data "archive_file" "jsonwebtoken_layer" {
  output_path = "files/jsonwebtoken-layer.zip"
  source_dir  = "${local.layers_path}/jsonwebtoken"
  type        = "zip"
}

data "archive_file" "mongodb_layer" {
  output_path = "files/mongodb-layer.zip"
  source_dir  = "${local.layers_path}/mongodb"
  type        = "zip"
}

data "archive_file" "sentry_layer" {
  output_path = "files/sentry-layer.zip"
  source_dir  = "${local.layers_path}/sentry"
  type        = "zip"
}

data "archive_file" "utils_layer" {
  output_path = "files/utils-layer.zip"
  source_dir  = "${local.layers_path}/utils"
  type        = "zip"
}

resource "aws_lambda_layer_version" "jsonwebtoken" {
  layer_name          = "jsonwebtoken-layer"
  description         = "JSON Web Token"
  filename            = data.archive_file.jsonwebtoken_layer.output_path
  source_code_hash    = data.archive_file.jsonwebtoken_layer.output_base64sha256
  compatible_runtimes = ["nodejs16.x"]
}

resource "aws_lambda_layer_version" "mongodb" {
  layer_name          = "mongodb-layer"
  description         = "MongoDB Client"
  filename            = data.archive_file.mongodb_layer.output_path
  source_code_hash    = data.archive_file.mongodb_layer.output_base64sha256
  compatible_runtimes = ["nodejs16.x"]
}

resource "aws_lambda_layer_version" "sentry" {
  layer_name          = "sentry-layer"
  description         = "Sentry Agent"
  filename            = data.archive_file.sentry_layer.output_path
  source_code_hash    = data.archive_file.sentry_layer.output_base64sha256
  compatible_runtimes = ["nodejs16.x"]
}

resource "aws_lambda_layer_version" "utils" {
  layer_name          = "utils-layer"
  description         = "Utils for response and event normalization"
  filename            = data.archive_file.utils_layer.output_path
  source_code_hash    = data.archive_file.utils_layer.output_base64sha256
  compatible_runtimes = ["nodejs16.x"]
}

/**
* Module: Clients
*/

resource "aws_lambda_function" "clients" {
  for_each = local.lambdas.clients

  function_name = each.value["name"]
  handler       = "${each.key}.handler"
  description   = each.value["description"]
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs16.x"

  filename         = data.archive_file.clients[each.key].output_path
  source_code_hash = data.archive_file.clients[each.key].output_base64sha256

  timeout     = each.value["timeout"]
  memory_size = each.value["memory"]

  layers = [
    aws_lambda_layer_version.mongodb.arn,
    aws_lambda_layer_version.sentry.arn,
    aws_lambda_layer_version.utils.arn
  ]

  // Enabling CloudWatch X-Ray
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DB_CONNECTION_URI         = local.db_connection_uri
      DB_NAME                   = local.db_name
      DEBUG                     = var.env == "dev"
      SENTRY_ENABLED            = false
      SENTRY_DSN                = ""
      SENTRY_TRACES_SAMPLE_RATE = 0.1
      SSM_PARAMETER_DB_USERNAME = local.ssm_parameters.mongodb_username
      SSM_PARAMETER_DB_PASSWORD = local.ssm_parameters.mongodb_password
    }
  }

  tags = {
    project = var.service_name
  }
}

resource "aws_lambda_function" "auth_login" {
  function_name = "${local.lambdas_prefix}Login"
  handler       = "login.handler"
  description   = "User authentication"
  role          = aws_iam_role.lambda_authentication_role.arn
  runtime       = "nodejs16.x"

  filename         = data.archive_file.auth_login.output_path
  source_code_hash = data.archive_file.auth_login.output_base64sha256

  timeout     = 15
  memory_size = 128

  layers = [
    aws_lambda_layer_version.mongodb.arn,
    aws_lambda_layer_version.sentry.arn,
    aws_lambda_layer_version.utils.arn
  ]

  // Enabling CloudWatch X-Ray
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      COGNITO_USER_POOL_ID      = aws_cognito_user_pool.user_pool.id
      COGNITO_APP_CLIENT_ID     = aws_cognito_user_pool_client.user_pool_client.id
      DB_CONNECTION_URI         = local.db_connection_uri
      DB_NAME                   = local.db_name
      DEBUG                     = var.env == "dev"
      SENTRY_ENABLED            = false
      SENTRY_DSN                = ""
      SENTRY_TRACES_SAMPLE_RATE = 0.1
      SSM_PARAMETER_DB_USERNAME = local.ssm_parameters.mongodb_username
      SSM_PARAMETER_DB_PASSWORD = local.ssm_parameters.mongodb_password
    }
  }

  tags = {
    project = var.service_name
  }
}

resource "aws_lambda_function" "api_authorizer" {
  function_name = "${local.lambdas_prefix}ApiAuthorizer"
  handler       = "apiAuthorizer.handler"
  description   = "Manage authorization of private endpoint requests"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs16.x"

  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256

  timeout     = 15
  memory_size = 128

  layers = [
    aws_lambda_layer_version.jsonwebtoken.arn,
    aws_lambda_layer_version.mongodb.arn,
    aws_lambda_layer_version.sentry.arn,
    aws_lambda_layer_version.utils.arn
  ]

  // Enabling CloudWatch X-Ray
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DB_CONNECTION_URI         = local.db_connection_uri
      DB_NAME                   = local.db_name
      DEBUG                     = var.env == "dev"
      SENTRY_ENABLED            = false
      SENTRY_DSN                = ""
      SENTRY_TRACES_SAMPLE_RATE = 0.1
      SSM_PARAMETER_DB_USERNAME = local.ssm_parameters.mongodb_username
      SSM_PARAMETER_DB_PASSWORD = local.ssm_parameters.mongodb_password
    }
  }

  tags = {
    project = var.service_name
  }
}

resource "aws_lambda_function" "verify_access_token" {
  function_name = "${local.lambdas_prefix}VerifyAccessToken"
  handler       = "verifyAccessToken.handler"
  description   = "Access Token Verification"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs16.x"

  filename         = data.archive_file.verify_access_token.output_path
  source_code_hash = data.archive_file.verify_access_token.output_base64sha256

  timeout     = 5
  memory_size = 128

  layers = [
    aws_lambda_layer_version.utils.arn
  ]

  // Enabling CloudWatch X-Ray
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DEBUG = var.env == "dev"
    }
  }

  tags = {
    project = var.service_name
  }
}

resource "aws_lambda_permission" "lambda_permission" {
  for_each = local.lambdas.clients

  statement_id  = "InvokeFunctionToAPILambdas"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.clients[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*/*"
}

resource "aws_lambda_permission" "lambda_authentication_permission" {
  statement_id  = "InvokeFunctionToAPILambdaAuthentication"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_login.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*/*"
}

resource "aws_lambda_permission" "lambda_api_authorizer_permission" {
  statement_id  = "InvokeFunctionToAPILambdaAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*/*"
}

resource "aws_lambda_permission" "lambda_verify_access_token_permission" {
  statement_id  = "InvokeFunctionToAPILambdas"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify_access_token.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*/*"
}
