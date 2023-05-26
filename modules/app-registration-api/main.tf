################################################################
#                          Variables                           #
################################################################

# The Display Name of the App Registration. Can be changed with creating a new resource.
variable "display_name" {
  type = string
}

# A list of objects with App Role definitions.
variable "app_roles" {
  type = list(object({
    display_name = string
    description  = string
    value        = string
  }))
}

# A list of objects with API Permissions. Each permissions will be granted admin consent.
variable "api_permissions" {
  type = list(object({
    application_id = string
    role_ids       = list(string)
  }))
}

################################################################
#                            Data                              #
################################################################

# Below data resources gets "Microsoft Graph" data.
data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

################################################################
#                      Azure Application                       #
################################################################

# Generate random UUID for the App Roles.
# Count will created a list with X numbers of unique uuid's,
# where X is the number of app roles. Each app role must it's own unique uuid.
resource "random_uuid" "app_roles" {
  count = length(var.app_roles)
}

# The Azure App Registration
resource "azuread_application" "main" {
  display_name = var.display_name

  # Set App Roles.
  # The index of each role in the list, is used to get a random uuid.
  # Each role must have its own unique uuid.
  dynamic "app_role" {
    for_each = { for index, role in var.app_roles : index => role }
    content {
      allowed_member_types = [
        "Application",
      ]
      description  = app_role.value.description
      display_name = app_role.value.display_name
      enabled      = true
      id           = random_uuid.app_roles[app_role.key].result
      value        = app_role.value.value
    }
  }

  # Set the defalt User.Read API permissions.
  # Atleast one API Permission must be set. The User.Read permissions is set incase no other permissions are.
  # If no permissions are set, the resources creation will fail.
  required_resource_access {
    resource_app_id = data.azuread_service_principal.msgraph.application_id # Microsoft Graph
    resource_access {
      id   = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  # Set API Permissions.
  dynamic "required_resource_access" {
    for_each = var.api_permissions

    content {
      resource_app_id = required_resource_access.value.application_id
      dynamic "resource_access" {
        for_each = required_resource_access.value.role_ids

        content {
          id   = resource_access.value
          type = "Role"
        }
      }
    }
  }
}

# Create Service Principal for the App Registration (required)
resource "azuread_service_principal" "main" {
  application_id = azuread_application.main.application_id
}

################################################################
#                     Grant Admin Consent                      #
################################################################

# Grant admin consent for all API Permissions.
module "grant_admin_consent" {
  for_each = { for index, value in var.api_permissions : index => value }

  source                  = "../grant-admin-consent"
  application_id          = azuread_application.main.application_id
  resource_application_id = each.value.application_id
  role_ids                = each.value.role_ids

  depends_on = [
    azuread_service_principal.main
  ]
}

################################################################
#                            Outputs                           #
################################################################

output "app_role_ids" {
  value = azuread_application.main.app_role_ids
}

output "application_id" {
  value = azuread_application.main.application_id
}

output "display_name" {
  value = azuread_application.main.display_name
}

output "api_permissions" {
  value = var.api_permissions
}

