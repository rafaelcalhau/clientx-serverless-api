/*
* api_authorizer_role
*/
resource "aws_iam_role" "api_authorizer_role" {
  name               = replace(title("${local.namespaced_service_name}ApiAuthInvocationRole"), "-", "")
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.api_invocation_assume_role.json
}
resource "aws_iam_policy" "api_authorizer_invocation_policy" {
  name   = replace(title("${local.namespaced_service_name}ApiAuthPermissionsPolicy"), "-", "")
  policy = data.aws_iam_policy_document.api_authorizer_invocation_doc.json

  tags = {
    project = var.service_name
  }
}
resource "aws_iam_role_policy_attachment" "api_auth_permissions_attachment" {
  role       = aws_iam_role.api_authorizer_role.name
  policy_arn = aws_iam_policy.api_authorizer_invocation_policy.arn
}

/*
* lambda_authentication_role
*/

resource "aws_iam_role" "lambda_authentication_role" {
  name               = replace(title("${local.namespaced_service_name}LambdaAuthenticationRole"), "-", "")
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_policy" "lambda_authentication_permissions_policy" {
  name   = replace(title("${local.namespaced_service_name}LambdaAuthenticationPermissionsPolicy"), "-", "")
  policy = data.aws_iam_policy_document.lambda_authentication_permissions_policy_doc.json

  tags = {
    project = var.service_name
  }
}
resource "aws_iam_role_policy_attachment" "lambda_authentication_permissions_attachment" {
  role       = aws_iam_role.lambda_authentication_role.name
  policy_arn = aws_iam_policy.lambda_authentication_permissions_policy.arn
}

/*
* lambda_role
*/

resource "aws_iam_role" "lambda_role" {
  name               = replace(title("${local.namespaced_service_name}LambdaRole"), "-", "")
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  path               = "/"

  tags = {
    project = var.service_name
  }
}
resource "aws_iam_policy" "lambda_permissions_policy" {
  name   = replace(title("${local.namespaced_service_name}LambdaPermissionsPolicy"), "-", "")
  policy = data.aws_iam_policy_document.lambda_permissions_policy_doc.json

  tags = {
    project = var.service_name
  }
}
resource "aws_iam_role_policy_attachment" "lambda_permissions_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_permissions_policy.arn
}