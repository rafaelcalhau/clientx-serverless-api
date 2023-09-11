resource "aws_cloudwatch_log_group" "clientx" {
  for_each = local.lambdas.clients

  name              = "/aws/lambda/${each.value.name}"
  retention_in_days = 3

  tags = {
    project = var.service_name
  }
}
