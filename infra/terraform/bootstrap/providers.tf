# El provider se configura con el kubeconfig que ya escribió la etapa `cluster`, no con
# atributos de un recurso de este módulo: así no hay valores desconocidos en tiempo de plan
# (ADR-0003, arquitectura §4).
provider "helm" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}
