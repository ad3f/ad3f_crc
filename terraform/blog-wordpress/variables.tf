#set default launch region to Sydney
variable "region-main" {
  type    = string
  default = "ap-southeast-2"
}

#default instance type
variable "default-instance" {
  type    = string
  default = "t2.micro"
}

#WP database name
variable "database_name" {
  type    = string
  default = "crc_wp_blog"
}

variable "rds-db-instance" {
  type    = string
  default = "db.t3.micro"
}

variable "route53-ad3f-zone-id" {
  type    = string
  default = "Z01539043J6BVUGSFJRDR"
}