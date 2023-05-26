################################################################
#                          Variables                           #
################################################################

# The application ID (client ID) of the application that you are working on.
variable "application_id" {
  type = string
}

# The application ID (client ID) of the application you wish to grant consent to.
variable "resource_application_id" {
  type = string
}

# A list of role ID's you wish to consent.
variable "role_ids" {
  type = list(string)
}

################################################################
#                            Data                              #
################################################################

data "azuread_service_principal" "client" {
  application_id = var.application_id
}

data "azuread_service_principal" "resource" {
  application_id = var.resource_application_id
}

################################################################
#                     Grant Admin Consent                      #
################################################################

resource "azuread_app_role_assignment" "main" {
  for_each = { for index, value in var.role_ids : index => value }

  app_role_id         = each.value
  principal_object_id = data.azuread_service_principal.client.object_id
  resource_object_id  = data.azuread_service_principal.resource.object_id
}

