terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.39.0"
    }
  }

  backend "local" {}
}

provider "azuread" {
  tenant_id = "<your-tenant-id-here>"
}


################################################################
#                      User Login Example                      #
################################################################

# Set the name of the module. Each module name has to be unique.
module "my_app_reg_module_name_01" {
  source           = "./modules/app-registration-spa"
  display_name     = "my-app-reg-display-name"

  redirect_uris = [
    "http://localhost:4200/usersignin",
    "https://example.org/usersignin"
  ]

  group_assignments = [
    "MyGroup_Admin",
    "MyGroup_User"
  ]
}

################################################################
#             API/Service-to-service Example no. 1             #
################################################################

# Set the name of the module. Each module name has to be unique.
module "my_app_reg_module_name_02" {
  source       = "./modules/app-registration-api"
  display_name = "my-app-reg-display-name"

  app_roles    = [
    {
      display_name = "MyService Read"
      value        = "MyService.Read"
      description  = "This is a description of what my role does."
    },
    {
      display_name = "MyService Write"
      value        = "MyService.Write"
      description  = "This is a description of what my role does."
    }
  ]

  api_permissions = []
}


################################################################
#             API/Service-to-service Example no. 2             #
################################################################

# Set the name of the module. Each module name has to be unique.
module "my_app_reg_module_name_03" {
  source           = "./modules/app-registration-api"
  display_name     = "my-app-reg-display-name"

  app_roles        = []

  api_permissions = [
    # You can reference other modules like below.
    {
      application_id = module.my_app_reg_module_name_02.application_id
      role_ids     = [
        module.my_app_reg_module_name_02.app_role_ids["MyService.Read"],
        module.my_app_reg_module_name_02.app_role_ids["MyService.Write"]
      ]
    },
    # Or if the application is not part of this Terraform script, you can hardcode the IDs.
    # Find the app/client ID and role ID's in the Azure Portal or by running below command.
    # az ad sp list --display-name <app-reg-name> -o yaml
    {
      application_id = "00000000-0000-0000-0000-000000000000"
      role_ids     = [
        "00000000-0000-0000-0000-000000000000",
        "00000000-0000-0000-0000-000000000000"
      ]
    },
  ]
}


################################################################
#                            Outputs                           #
################################################################

output "app_registrations" {
  value = { app_registrations = [
    {
      display_name      = module.my_app_reg_module_name_01.display_name
      application_id    = module.my_app_reg_module_name_01.application_id
      roles             = module.my_app_reg_module_name_01.app_role_ids
      group_assignments = module.my_app_reg_module_name_01.group_assignments
      redirect_uris     = module.my_app_reg_module_name_01.redirect_uris
    },
    {
      display_name    = module.my_app_reg_module_name_02.display_name
      application_id  = module.my_app_reg_module_name_02.application_id
      roles           = module.my_app_reg_module_name_02.app_role_ids
      api_permissions = module.my_app_reg_module_name_02.api_permissions
    },
    {
      display_name    = module.my_app_reg_module_name_03.display_name
      application_id  = module.my_app_reg_module_name_03.application_id
      roles           = module.my_app_reg_module_name_03.app_role_ids
      api_permissions = module.my_app_reg_module_name_03.api_permissions
    }
  ]}
}