resource "aws_api_gateway_rest_api" "api" {
  name = "CustomerX-API"

  endpoint_configuration {
    types = ["EDGE"]
  }

  tags = {
    project = var.service_name
  }
}

resource "aws_api_gateway_resource" "root_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "customers_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.root_resource.id
  path_part   = "customers"
}

resource "aws_api_gateway_resource" "customer_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.customers_resource.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "customer_attach_service_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.customer_id_resource.id
  path_part   = "attach-service"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_method.AddCustomer,
    aws_api_gateway_method.AttachServiceToCustomer,
    aws_api_gateway_method.DeleteCustomer,
    aws_api_gateway_method.GetCustomer,
    aws_api_gateway_method.GetCustomers,
    aws_api_gateway_method.UpdateCustomer,
    aws_api_gateway_integration.AddCustomerIntegration,
    aws_api_gateway_integration.AttachServiceToCustomer,
    aws_api_gateway_integration.DeleteCustomerIntegration,
    aws_api_gateway_integration.GetCustomerIntegration,
    aws_api_gateway_integration.GetCustomersIntegration,
    aws_api_gateway_integration.UpdateCustomerIntegration
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.root_resource,
      aws_api_gateway_resource.customers_resource,
      aws_api_gateway_resource.customer_id_resource,
      aws_api_gateway_resource.customer_attach_service_resource,
      aws_api_gateway_method.AddCustomer,
      aws_api_gateway_method.AttachServiceToCustomer,
      aws_api_gateway_method.DeleteCustomer,
      aws_api_gateway_method.GetCustomer,
      aws_api_gateway_method.GetCustomers,
      aws_api_gateway_method.UpdateCustomer,
      aws_api_gateway_integration.AddCustomerIntegration,
      aws_api_gateway_integration.AttachServiceToCustomer,
      aws_api_gateway_integration.DeleteCustomerIntegration,
      aws_api_gateway_integration.GetCustomersIntegration,
      aws_api_gateway_integration.GetCustomerIntegration,
      aws_api_gateway_integration.UpdateCustomerIntegration,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id        = aws_api_gateway_deployment.api_deployment.id
  rest_api_id          = aws_api_gateway_rest_api.api.id
  stage_name           = var.env
  xray_tracing_enabled = var.env == "dev"
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "${var.env}${title(var.service_name)}UserAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.api.id
  authorizer_uri         = aws_lambda_function.api_authorizer.invoke_arn
  identity_source        = "method.request.header.Authorization"
  provider_arns          = [aws_cognito_user_pool.user_pool.arn]
  authorizer_credentials = aws_iam_role.api_auth_role.arn
  type                   = "COGNITO_USER_POOLS"
}