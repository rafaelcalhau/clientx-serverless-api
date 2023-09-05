resource "aws_cloudwatch_log_group" "customerx" {
  for_each = local.lambdas.customers

  name              = "/aws/lambda/${each.value.name}"
  retention_in_days = 3

  tags = {
    project = var.service_name
  }
}
