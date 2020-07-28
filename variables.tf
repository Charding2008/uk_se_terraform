variable "prefix" {
  description = "prefix for resources created"
  default     = "charles-f5-demo"
}
variable "ssh_key_name" {
  description = "RSA key"
  default     = "charles_id_rsa.pub"
}

variable "uk_se_name" {
  description = "UK SE name tag"
  default     = "charles"
}

variable "f5_ami_search_name" {
  description = "search term to find the appropriate F5 AMI for current region"
  default     = "F5*BIGIP-15.1.0.4*Better*25Mbps*"
}

variable "aws_secret_name" {
  description = "name of secret created in aws secrets manage"
  default     = "my_bigip_password"
}

variable "username" {
  description = "big-ip username"
  default     = "admin"
}

variable "password" {
  description = "big-ip password"
  default     = ""
}

variable "address" {
  description = "big-ip address"
  default     = ""
}

variable "port" {
  description = "big-ip port, 443 default, use 8443 for single NIC"
  default     = "443"
}

variable "libs_dir" {
  description = "Destination directory on the BIG-IP to download the A&O Toolchain RPMs"
  default     = "/config/cloud/aws/node_modules"
}

variable "onboard_log" {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  default     = "/var/log/startup-script.log"
}

