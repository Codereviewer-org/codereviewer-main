variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "capacity_min" {
  type    = number
  default = 1
}

variable "capacity_max" {
  type    = number
  default = 3
}

variable "zones" {
  description = "Availability zones supported by the selected region. Use an empty list for non-zonal regions."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
