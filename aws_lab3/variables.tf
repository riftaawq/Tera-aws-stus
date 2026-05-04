variable "disk_name" {
  description = "Назва диска"
  type        = string
}

variable "disk_size" {
  description = "Розмір диска в ГБ"
  type        = number
  default     = 32
}