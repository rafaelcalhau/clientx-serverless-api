data "archive_file" "authorizer" {
  output_path = "files/apiAuthorizer.zip"
  source_file = "${local.lambdas_path}/apiAuthorizer.js"
  type        = "zip"
}

data "archive_file" "customers" {
  for_each = local.lambdas.customers

  output_path = "files/customers${each.key}.zip"
  source_file = "${local.lambdas_path}/customers/${each.key}.js"
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
* Module: Customers
*/

resource "aws_lambda_function" "customers" {
  for_each = local.lambdas.customers

  function_name = each.value["name"]
  handler       = "${each.key}.handler"
  description   = each.value["description"]
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs16.x"

  filename         = data.archive_file.customers[each.key].output_path
  source_code_hash = data.archive_file.customers[each.key].output_base64sha256

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

resource "aws_lambda_function" "api_authorizer" {
  function_name = "${local.lambdas_prefix}ApiAuthorizer"
  handler       = "ApiAuthorizer.handler"
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

resource "aws_lambda_permission" "lambda_permission" {
  for_each = local.lambdas.customers

  statement_id  = "InvokeFunctionToAPILambdas"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.customers[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*/*"
}

resource "aws_lambda_permission" "authorizer_lambda_permission" {
  statement_id  = "InvokeFunctionToAPILambdaAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*/*"
}
