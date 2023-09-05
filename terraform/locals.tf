locals {
  db_connection_uri = "mongodb+srv://<username>:<password>@cluster0.fv6iow2.mongodb.net/${var.env}"
  db_name           = "customerx"

  namespaced_service_name           = "${var.service_name}-${var.env}"
  namespaced_service_name_fn_prefix = replace("${var.service_name}-${title(var.env)}", "-", "")

  lambdas_path   = "${path.module}/../lambdas"
  lambdas_prefix = "${var.env}${title(var.service_name)}"
  layers_path    = "${path.module}/../lambdas/layers"

  lambdas = {
    customers : {
      AddCustomer = {
        name        = "${local.lambdas_prefix}AddCustomer"
        description = "Add a new customer"
        memory      = 128
        timeout     = 15
      }
      AttachServiceToCustomer = {
        name        = "${local.lambdas_prefix}AttachServiceToCustomer"
        description = "Attach a service to a customer"
        memory      = 128
        timeout     = 15
      }
      DeleteCustomer = {
        name        = "${local.lambdas_prefix}DeleteCustomer"
        description = "Soft delete a customer"
        memory      = 128
        timeout     = 15
      }
      GetCustomers = {
        name        = "${local.lambdas_prefix}GetCustomers"
        description = "Get customers"
        memory      = 128
        timeout     = 15
      }
      UpdateCustomer = {
        name        = "${local.lambdas_prefix}UpdateCustomer"
        description = "Update a customer"
        memory      = 128
        timeout     = 15
      }
    }
  }

  ssm_parameters = {
    mongodb_username = "${var.service_name}_mongodb_username"
    mongodb_password = "${var.service_name}_mongodb_password"
  }
}