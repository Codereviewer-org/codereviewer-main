variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "address_space" {
  type    = list(string)
  default = ["10.20.0.0/16"]
}

variable "subnet_prefixes" {
  description = "CIDR lists for aks, application_gateway, database, private_endpoint, and vm subnets."
  type = object({
    aks                 = list(string)
    application_gateway = list(string)
    database            = list(string)
    private_endpoint    = list(string)
    vm                  = list(string)
  })
}

variable "admin_source_cidr" {
  description = "CIDR allowed to SSH to future jumpbox VMs. Use a narrow trusted CIDR."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
