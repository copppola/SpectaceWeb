terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "=4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Creamos el grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.location
}

# Creamos el aks
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.project_name}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.project_name}-dns"

# Definimos el nombre del RG del node pool
  node_resource_group = "${var.project_name}-aks-nodos-rg"

# Definimos el node pool con 1 nodo inicial y usamos VMSS
  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_B2s"
    type       = "VirtualMachineScaleSets"
  }

# Creamos una Managed Identity asociada al cluster
  identity {
    type = "SystemAssigned"
  }

# Definimos modo de conexión a la red y tipo de Load Balancer
  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }
}

# Exponemos el kubeconfig y lo hacemos sensible para que no se imprima con plan/apply
output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}