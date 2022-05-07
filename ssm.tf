resource "aws_ssm_parameter" "db_username" {
  name  = "/db/username"
  type  = "String"
  value = "root"
  description = "User name for database"
}

resource "aws_ssm_parameter" "db_raw_password" {
  name  = "/db/raw_password"
  type  = "SecureString"
  value = "uninitialized"
  description = "Password for database"

  lifecycle {
    ignore_changes = [value]
  }
}
