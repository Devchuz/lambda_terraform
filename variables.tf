variable "service_names" {
  description = "A map of service names to deploy"
  type        = map(string)
}

variable "region" {
  description = "Region where AWS resources will be deployed"
  default     = "us-east-1"
}

# Puedes agregar más variables para nombres de servicios o configuraciones no sensibles
