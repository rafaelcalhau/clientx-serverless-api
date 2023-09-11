resource "aws_api_gateway_rest_api" "api" {
  name = "ClientX-API"

  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "ClientX"
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
      "/v1/{proxy+}" = {
        options = {
          x-amazon-apigateway-cors = {
            allowOrigins     = ["*"]
            allowCredentials = true
            exposeHeaders = [
              "x-apigateway-header",
              "x-amz-date",
              "content-type"
            ]
            maxAge       = 3600
            allowMethods = ["*"]
            allowHeaders = [
              "x-apigateway-header",
              "x-amz-date",
              "content-type"
            ]
          }
          x-amazon-apigateway-integration = {
            httpMethod           = "OPTIONS"
            payloadFormatVersion = "1.0"
            type                 = "MOCK"
            requestTemplates = {
              "application/json" = "{\"statusCode\": 200}"
            }
            passthroughBehavior = "WHEN_NO_MATCH"
            contentHandling     = "CONVERT_TO_TEXT"
            timeoutInMillis     = 29000
            responses = {
              default = {
                statusCode = 200
                responseParameters = {
                  "method.response.header.Access-Control-Allow-Headers" : "'*'"
                  "method.response.header.Access-Control-Allow-Methods" : "'*'"
                  "method.response.header.Access-Control-Allow-Origin" : "'*'"
                }
              }
            }
          }
          responses = {
            200 = {
              description = "200 response"
              headers = {
                Access-Control-Allow-Headers = {
                  schema = {
                    type = "string"
                  }
                }
                Access-Control-Allow-Methods = {
                  schema = {
                    type = "string"
                  }
                }
                Access-Control-Allow-Origin = {
                  schema = {
                    type = "string"
                  }
                }
              }
            }
          }
        }
      }
      "/v1/clients" = {
        get = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.clients["GetClients"].invoke_arn
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
            uri                  = aws_lambda_function.clients["AddClient"].invoke_arn
          }
        }
      }
      "/v1/clients/{id}" = {
        delete = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.clients["DeleteClient"].invoke_arn
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
            uri                  = aws_lambda_function.clients["GetClients"].invoke_arn
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
            uri                  = aws_lambda_function.clients["UpdateClient"].invoke_arn
          }
        }
      }
      "/v1/clients/{id}/attach-service" = {
        post = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.clients["AttachServiceToClient"].invoke_arn
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
      "/v1/verify-access-token" = {
        get = {
          security = [{
            authorizer = []
          }]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.verify_access_token.invoke_arn
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
