//------------------------------------------------------------------------------
// CONFIGURE PROVIDERS
//------------------------------------------------------------------------------
provider "azurerm" {
  features {}
}

//------------------------------------------------------------------------------
// CONFIGURE GLOBAL VARIABLES
//------------------------------------------------------------------------------
variables {
  resource_group = {
    name     = "rg-hashitalks"
    location = "swedencentral"
    tags = {
      team        = "HashiTalks Team"
      project     = "HashiTalks Project"
      cost_center = "1234"
    }
  }
  name_suffix = "hashitalks"
  endpoints = [
    {
      name     = "google-dns"
      target   = "8.8.8.8"
      priority = 10
      enabled  = true
    }
  ]
}

//------------------------------------------------------------------------------
// VARIABLE VALIDATION TESTS
//------------------------------------------------------------------------------
run "name_suffix_must_start_with_alphanumerics" {
  command = plan

  variables {
    name_suffix = "-thisnameisinvalid"
  }

  expect_failures = [
    var.name_suffix,
  ]
}

run "name_suffix_must_end_with_alphanumerics" {
  command = plan

  variables {
    name_suffix = "thisnameisinvalid-"
  }

  expect_failures = [
    var.name_suffix,
  ]
}

run "name_suffix_should_only_contain_alphanumerics_dash_period" {
  command = plan

  variables {
    name_suffix = "this name is invalid"
  }

  expect_failures = [
    var.name_suffix,
  ]
}

run "name_suffix_should_not_be_too_long" {
  command = plan

  variables {
    name_suffix = replace("**********", "*", "abcdefghijkl")
  }

  expect_failures = [
    var.name_suffix,
  ]
}

//------------------------------------------------------------------------------
// RESOURCE ATTRIBUTE TESTS
//------------------------------------------------------------------------------
run "profile_should_inherit_tags_from_resource_group" {
  command = plan

  assert {
    condition     = azurerm_traffic_manager_profile.this.tags == var.resource_group.tags
    error_message = "Tags are not inherited from resource group"
  }
}

//------------------------------------------------------------------------------
// FUNCTIONALITY TESTS
//------------------------------------------------------------------------------
run "setup_resource_group" {
  command = apply

  variables {
    name_suffix = "hashitalks"
    location    = "swedencentral"
    tags = {
      team        = "HashiTalks Team"
      project     = "HashiTalks Project"
      cost_center = "1234"
    }
  }

  module {
    source  = "app.terraform.io/mattias-fjellstrom/resource-group-module/hashitalks"
    version = "1.0.1"
  }
}

run "validate_traffic_manager_attributes" {
  command = apply

  variables {
    resource_group = run.setup_resource_group.resource_group
  }

  assert {
    condition     = azurerm_traffic_manager_profile.this.profile_status == "Enabled"
    error_message = "Traffic manager status is set to disabled"
  }

  assert {
    condition     = azurerm_traffic_manager_profile.this.dns_config.ttl <= 60
    error_message = "DNS TTL is set too high"
  }
}
