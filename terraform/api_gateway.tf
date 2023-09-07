resource "aws_api_gateway_rest_api" "api" {
  name = "CustomerX-API"

  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "CustomerX"
      version = "1.0"
    }
    components = {
      securitySchemes = {
        authorizer = {
          type                         = "apiKey"
          name                         = "Authorization"
          in                           = "header"
          description                  = "Cognito User Pool Authorization"
          x-amazon-apigateway-authtype = "cognito_user_pools"
          x-amazon-apigateway-authorizer = {
            type                  = "cognito_user_pools"
            authorizerUri         = aws_lambda_function.api_authorizer.invoke_arn
            authorizerCredentials = aws_iam_role.api_authorizer_role.arn
            identitySource        = "method.request.header.Authorization"
            providerARNs          = [aws_cognito_user_pool.user_pool.arn]
          }
        }
      }
    }
    paths = {
      "/v1/customers" = {
        get = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.customers["GetCustomers"].invoke_arn
          }
        }
        post = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.customers["AddCustomer"].invoke_arn
          }
        }
      }
      "/v1/customers/{id}" = {
        delete = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.customers["DeleteCustomer"].invoke_arn
          }
        }
        get = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.customers["GetCustomers"].invoke_arn
          },
        }
        put = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.customers["UpdateCustomer"].invoke_arn
          }
        }
      }
      "/v1/customers/{id}/attach-service" = {
        post = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.customers["AttachServiceToCustomer"].invoke_arn
          }
        }
      }
      "/v1/login" = {
        post = {
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.auth_login.invoke_arn
          }
        }
      }
    },
  })

  endpoint_configuration {
    types = ["EDGE"]
  }

  tags = {
    project = var.service_name
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.api.body,
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
