locals {
  db_connection_uri = "mongodb+srv://<username>:<password>@cluster0.fv6iow2.mongodb.net/${var.env}"
  db_name           = "clientx"

  namespaced_service_name           = "${var.service_name}-${var.env}"
  namespaced_service_name_fn_prefix = replace("${var.service_name}-${title(var.env)}", "-", "")

  lambdas_path   = "${path.module}/../lambdas"
  lambdas_prefix = "${var.env}${title(var.service_name)}"
  layers_path    = "${path.module}/../lambdas/layers"

  lambdas = {
    clients : {
      AddClient = {
        name        = "${local.lambdas_prefix}AddClient"
        description = "Add a new client"
        memory      = 128
        timeout     = 15
      }
      AttachServiceToClient = {
        name        = "${local.lambdas_prefix}AttachServiceToClient"
        description = "Attach a service to a client"
        memory      = 128
        timeout     = 15
      }
      DeleteClient = {
        name        = "${local.lambdas_prefix}DeleteClient"
        description = "Soft delete a client"
        memory      = 128
        timeout     = 15
      }
      GetClients = {
        name        = "${local.lambdas_prefix}GetClients"
        description = "Get clients"
        memory      = 128
        timeout     = 15
      }
      UpdateClient = {
        name        = "${local.lambdas_prefix}UpdateClient"
        description = "Update a client"
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