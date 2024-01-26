resource "azurerm_traffic_manager_profile" "this" {
  name                = "tm-${var.name_suffix}"
  resource_group_name = var.resource_group.name

  tags = var.resource_group.tags

  dns_config {
    ttl           = 60
    relative_name = var.name_suffix
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 10
    timeout_in_seconds           = 5
    tolerated_number_of_failures = 3
    expected_status_code_ranges  = ["200-399"]
  }

  traffic_routing_method = "Priority"
}

locals {
  endpoint_map = {
    for _, endpoint in var.endpoints : endpoint.name => endpoint
  }
}

resource "azurerm_traffic_manager_external_endpoint" "endpoints" {
  for_each = local.endpoint_map

  profile_id        = azurerm_traffic_manager_profile.this.id
  name              = each.value.name
  target            = each.value.target
  endpoint_location = var.resource_group.location
  priority          = each.value.priority
  enabled           = each.value.enabled

  custom_header {
    name  = "Host"
    value = each.value.target
  }
}

data "azurerm_resource_group" "dns" {
  name = "dns"
}

data "azurerm_dns_zone" "mattiasfjellstromcom" {
  resource_group_name = data.azurerm_resource_group.dns.name
  name                = "mattiasfjellstrom.com"
}

resource "azurerm_dns_cname_record" "tm" {
  resource_group_name = data.azurerm_resource_group.dns.name
  name                = "hashitalks"
  zone_name           = data.azurerm_dns_zone.mattiasfjellstromcom.name
  ttl                 = 60
  target_resource_id  = azurerm_traffic_manager_profile.this.id
}
