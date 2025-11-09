variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true # (중요) plan/apply 시 터미널에 비밀번호가 안 보이게 함
}