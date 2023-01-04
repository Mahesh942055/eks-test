variable "aws_region" {
  description = "region"
  type = string
  default = "ap-south-1"
}
variable "my_alb_name" {
  default = "alb-with-terra"
}
variable "my_tg_name" {
  default = "tg-with-terra"
}
variable "my-task-def-name" {
  default = "laravel-mysql-terra"
}
variable "my-task-def-vol" {
  default = "laravelsql-vol"
}