################################################################
#                          Variables                           #
################################################################

# The Display Name of the App Registration. Can be changed with creating a new resource.
variable "display_name" {
  type = string
}

# A list of redirect URI's for the App Registration. Can be empty.
variable "redirect_uris" {
  type = list(string)
}

# A list of groups to be assigned to the Enterprise Application. Can be empty.
variable "group_assignments" {
  type = list(string)
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

# Create the Azure Application
resource "azuread_application" "main" {
  display_name            = var.display_name
  group_membership_claims = ["ApplicationGroup"]

  # Set the optinal claims to get groups names instead of GUID's in the access token.
  optional_claims {
    access_token {
      additional_properties = [
        "sam_account_name",
      ]
      essential = true
      name      = "groups"
    }

    id_token {
      additional_properties = [
        "sam_account_name",
      ]
      essential = true
      name      = "groups"
    }
  }

  # Set the redirect URI's, if any.
  single_page_application {
    redirect_uris = var.redirect_uris
  }

  # Set the defalt User.Read API permissions.
  required_resource_access {
    resource_app_id = data.azuread_service_principal.msgraph.application_id # Microsoft Graph

    resource_access {
      id   = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }
}

# Create a Service Principal for the App Registration (required)
resource "azuread_service_principal" "user" {
  application_id = azuread_application.main.application_id
}


################################################################
#                     Default User Grant                       #
################################################################

# Gives admin consent on the User.Read permission.
resource "azuread_service_principal_delegated_permission_grant" "main" {
  service_principal_object_id          = azuread_service_principal.user.object_id
  resource_service_principal_object_id = data.azuread_service_principal.msgraph.object_id
  claim_values                         = ["User.Read"]
}

################################################################
#                      Group Assignments                       #
################################################################

# Assigns the groups to the Enterprise Application, if any.
module "group_assignemnts" {
  for_each       = toset(var.group_assignments)
  source         = "../group-assignment"
  application_id = azuread_service_principal.user.application_id
  group_name     = each.value
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

output "group_assignments" {
  value = var.group_assignments
}

output "redirect_uris" {
  value = var.redirect_uris
}

