# Clúster Kubernetes del laboratorio (O2, RF-07).
#
# Un único nodo control-plane que también ejecuta cargas de trabajo: suficiente para un
# laboratorio con dos entornos lógicos separados por namespaces y la opción más ligera
# en memoria (requisito de 8 GB de la PEC1). Ver ADR-0002.
#
# Responsabilidad de este módulo: solo el clúster. Argo CD y el resto de componentes se
# instalan en etapas posteriores para evitar dependencias entre providers (ADR-0003).

resource "kind_cluster" "lab" {
  name            = var.cluster_name
  node_image      = var.node_image
  kubeconfig_path = var.kubeconfig_path
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # El controlador de ingress (fase S5) se programa en el nodo con esta etiqueta,
      # que es el que publica los puertos 80/443 en el host.
      labels = {
        "ingress-ready" = "true"
      }

      extra_port_mappings {
        container_port = 80
        host_port      = var.http_port
        listen_address = var.listen_address
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = var.https_port
        listen_address = var.listen_address
        protocol       = "TCP"
      }
    }
  }
}
