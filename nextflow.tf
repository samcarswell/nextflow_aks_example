resource "random_pet" "prefix" {}

provider "azurerm" {
  version = "=2.25.0"
  features {}
}

provider "kubernetes" {
  version          = "=1.13.2"
  load_config_file = "false"

  host = azurerm_kubernetes_cluster.default.kube_config.0.host

  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

resource "azurerm_resource_group" "default" {
  name     = "${random_pet.prefix.id}-rg"
  location = "australiaeast"
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Demo"
  }
}

resource "azurerm_storage_account" "default" {
  name                     = replace("${random_pet.prefix.id}storage", "-", "")
  resource_group_name      = azurerm_resource_group.default.name
  location                 = azurerm_resource_group.default.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "default" {
  name                 = "${azurerm_storage_account.default.name}share"
  storage_account_name = azurerm_storage_account.default.name
}

resource "kubernetes_persistent_volume" "default" {
  metadata {
    name = "workflow-volume"

    labels = {
      type = "local"
    }
  }

  spec {
    capacity = {
      storage = "5Ti"
    }

    access_modes       = ["ReadWriteMany"]
    storage_class_name = "azurefile"
    persistent_volume_source {
      azure_file {
        secret_name = "azure-file-creds"
        share_name  = azurerm_storage_share.default.name
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "default" {
  metadata {
    name = "workflow-volume-claim"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
    volume_name        = kubernetes_persistent_volume.default.metadata.0.name
    storage_class_name = "azurefile"
  }
}

resource "kubernetes_role" "pod_reader" {
  metadata {
    name      = "pod-reader"
    namespace = "default"
  }

  rule {
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
    api_groups = [""]
    resources  = ["pods", "services", "pods/status"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions"]
    resources  = ["deployments"]
  }
}

resource "kubernetes_role_binding" "default_pod_reader" {
  metadata {
    name      = "default-pod-reader"
    namespace = "default"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "pod-reader"
  }
}

resource "kubernetes_secret" "secret" {
  metadata {
    name = "azure-file-creds"
  }

  data = {
    azurestorageaccountkey  = azurerm_storage_account.default.primary_access_key
    azurestorageaccountname = azurerm_storage_account.default.name
  }
}

