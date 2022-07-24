################################################################
#                          Variables                           #
################################################################

# The application ID (client ID) of the application that you are working on.
variable "application_id" {
  type = string
}

# The group name to assign.
variable "group_name" {
  type = string
}

################################################################
#                            Data                              #
################################################################

data "azuread_service_principal" "assignment" {
  application_id = var.application_id
}

data "azuread_group" "assignment" {
  display_name     = var.group_name
  security_enabled = true
}

################################################################
#                      Group Assignment                        #
################################################################

resource "azuread_app_role_assignment" "group_assignment" {
  app_role_id         = "00000000-0000-0000-0000-000000000000" # default assignment level
  principal_object_id = data.azuread_group.assignment.id
  resource_object_id  = data.azuread_service_principal.assignment.object_id
}
