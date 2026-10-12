output "cluster_name" {
  description = "Nombre del clúster kind."
  value       = kind_cluster.lab.name
}

output "kube_context" {
  description = "Contexto kubectl del laboratorio."
  value       = "kind-${kind_cluster.lab.name}"
}

output "kubeconfig_path" {
  description = "Ruta del kubeconfig generado. Lo consumen los scripts y la etapa de bootstrap."
  value       = kind_cluster.lab.kubeconfig_path
}

output "api_endpoint" {
  description = "Endpoint del API server de Kubernetes."
  value       = kind_cluster.lab.endpoint
}
