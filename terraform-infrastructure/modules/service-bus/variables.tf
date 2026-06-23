variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "queue_name" {
  type    = string
  default = "review-jobs"
}

variable "tags" {
  type    = map(string)
  default = {}
}
