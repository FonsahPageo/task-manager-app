resource "aws_db_subnet_group" "main" {
  count = var.create_rds ? 1 : 0

  name       = "${var.project}-db"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project}-db"
  }
}

resource "aws_db_instance" "main" {
  count = var.create_rds ? 1 : 0

  identifier              = "${var.project}-${var.environment}"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main[0].name
  vpc_security_group_ids  = [aws_security_group.rds[0].id]
  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 1
  skip_final_snapshot     = true
  apply_immediately       = true

  tags = {
    Name = "${var.project}-${var.environment}"
  }
}
