provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "tf-resource-group"
  location = "East US"
}