variable "folder_id" {
  description = "folder_id"
  type        = string
}
variable "token" {
  description = "token_yc"
  type        = string
}

variable "service" {
  description = "service_account_id"
  type        = string
}

variable "zone" {
  description = "zone_in_yandex"
  type        = string
  default     = "ru-central1-a"
}
#здесь я ошиблась, присвоила эту переменную сети, а не названию ВМ, поэтому описание изменила
variable "vpc_name" {
  description = "network-name"
  type        = string
  default     = "holy-socks"
}

variable "subnet_name" {
  description = "subnet_name"
  type        = string
  default     = "holysocks-subnet"
}
variable "ssh_private_key_path" {
  description = "ssh_private_for_workers"
  type        = string
}
