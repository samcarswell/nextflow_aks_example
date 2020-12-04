output "az_aks_get_credentials_command" {
  value = "az aks get-credentials --name ${azurerm_kubernetes_cluster.default.name} --resource-group ${azurerm_resource_group.default.name}"
}
