variable "cluster_name" {
  description = "Nombre del clúster kind. El contexto kubectl resultante es kind-<cluster_name>."
  type        = string
  default     = "idp-lab"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.cluster_name))
    error_message = "cluster_name debe ser un nombre DNS-1123 (minúsculas, dígitos y guiones)."
  }
}

variable "node_image" {
  description = "Imagen del nodo kind, fijada por digest. Se inyecta desde versions.env (KIND_NODE_IMAGE)."
  type        = string

  validation {
    condition     = can(regex("^kindest/node:v[0-9.]+@sha256:[a-f0-9]{64}$", var.node_image))
    error_message = "node_image debe tener la forma kindest/node:vX.Y.Z@sha256:<digest>."
  }
}

variable "kubeconfig_path" {
  description = "Ruta donde se escribe el kubeconfig del laboratorio (fuera de ~/.kube/config)."
  type        = string
}

variable "listen_address" {
  description = "Dirección del host en la que se publican los puertos del ingress. 127.0.0.1 evita exponer el laboratorio a la red local."
  type        = string
  default     = "127.0.0.1"
}

variable "http_port" {
  description = "Puerto HTTP del host mapeado al puerto 80 del nodo (ingress)."
  type        = number
  default     = 80
}

variable "https_port" {
  description = "Puerto HTTPS del host mapeado al puerto 443 del nodo (ingress)."
  type        = number
  default     = 443
}
