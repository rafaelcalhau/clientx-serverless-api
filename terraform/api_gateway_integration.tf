resource "aws_api_gateway_integration" "AddCustomerIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.customers_resource.id
  http_method             = aws_api_gateway_method.AddCustomer.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.customers["AddCustomer"].invoke_arn
}

resource "aws_api_gateway_integration" "AttachServiceToCustomer" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.customer_attach_service_resource.id
  http_method             = aws_api_gateway_method.AttachServiceToCustomer.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.customers["AttachServiceToCustomer"].invoke_arn
}

resource "aws_api_gateway_integration" "DeleteCustomerIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.customer_id_resource.id
  http_method             = aws_api_gateway_method.DeleteCustomer.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.customers["DeleteCustomer"].invoke_arn
}

resource "aws_api_gateway_integration" "GetCustomerIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.customer_id_resource.id
  http_method             = aws_api_gateway_method.GetCustomer.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.customers["GetCustomers"].invoke_arn
}

resource "aws_api_gateway_integration" "GetCustomersIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.customers_resource.id
  http_method             = aws_api_gateway_method.GetCustomers.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.customers["GetCustomers"].invoke_arn
}

resource "aws_api_gateway_integration" "UpdateCustomerIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.customer_id_resource.id
  http_method             = aws_api_gateway_method.UpdateCustomer.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.customers["UpdateCustomer"].invoke_arn
}
