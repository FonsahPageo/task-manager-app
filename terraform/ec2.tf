data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  create_key_pair = var.key_name == ""
  key_name        = local.create_key_pair ? aws_key_pair.host[0].key_name : var.key_name
}

resource "tls_private_key" "host" {
  count     = local.create_key_pair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "host" {
  count      = local.create_key_pair ? 1 : 0
  key_name   = "${var.project}-${var.environment}"
  public_key = tls_private_key.host[0].public_key_openssh
}

resource "local_file" "host_private_key" {
  count           = local.create_key_pair ? 1 : 0
  content         = tls_private_key.host[0].private_key_pem
  filename        = "${path.module}/${var.project}-${var.environment}.pem"
  file_permission = "0600"
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.host.name
  key_name               = local.key_name
  user_data              = file("${path.module}/user_data.sh")
  # Do NOT rebuild the instance just because user_data.sh changed: Jenkins and
  # its jobs live on the host and a rebuild wipes them. Rebuild deliberately
  # by passing -replace=aws_instance.app.
  user_data_replace_on_change = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-eip"
  }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app.id
}
