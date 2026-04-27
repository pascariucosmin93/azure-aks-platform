resource "azurerm_redis_cache" "main" {
  name                          = "${var.prefix}-redis"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  capacity                      = var.capacity
  family                        = var.sku_name == "Premium" ? "P" : "C"
  sku_name                      = var.sku_name
  non_ssl_port_enabled          = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  zones                         = var.sku_name == "Premium" ? ["1", "2", "3"] : null

  redis_configuration {
    maxmemory_policy = "volatile-lru"
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "redis" {
  name                = "${var.prefix}-redis-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.prefix}-redis-psc"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "redis-dns-group"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}
