data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Role for the application host: pull images from ECR, plus SSM for optional
resource "aws_iam_role" "host" {
  name               = "${var.project}-host"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "host_ecr_read" {
  role       = aws_iam_role.host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Jenkins runs on the same host and pushes images to ECR.
resource "aws_iam_role_policy_attachment" "host_ecr_write" {
  role       = aws_iam_role.host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# PowerUser does not cover lifecycle policies, which the Jenkinsfile manages.
resource "aws_iam_role_policy" "host_ecr_lifecycle" {
  name = "ecr-lifecycle"
  role = aws_iam_role.host.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:PutLifecyclePolicy",
        "ecr:GetLifecyclePolicy",
        "ecr:DeleteLifecyclePolicy",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "host_ssm" {
  role       = aws_iam_role.host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "host" {
  name = "${var.project}-host"
  role = aws_iam_role.host.name
}

# Role for the Jenkins agent: push images to ECR.
# Attach this instance profile to the EC2 instance that runs Jenkins.
resource "aws_iam_role" "jenkins" {
  name               = "${var.project}-jenkins"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_push" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project}-jenkins"
  role = aws_iam_role.jenkins.name
}
