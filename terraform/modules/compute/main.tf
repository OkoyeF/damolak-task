resource "aws_iam_role" "app" {
  name = "${var.environment}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.environment}-cloudwatch-logs"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "arn:aws:logs:*:*:log-group:/damolak-task/${var.environment}:*"
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.environment}-app-profile"
  role = aws_iam_role.app.name
}

resource "aws_security_group" "app" {
  name   = "${var.environment}-app-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-app-sg" }
}

resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker aws-cli
    systemctl start docker
    systemctl enable docker
    systemctl start amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    REGION=$$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    ECR_REGISTRY=$$(echo "${var.ecr_image_uri}" | cut -d'/' -f1)
    aws ecr get-login-password --region $$REGION | docker login --username AWS --password-stdin $$ECR_REGISTRY
    docker pull ${var.ecr_image_uri}
    docker run -d \
      --name damolak-app \
      --restart always \
      -p ${var.app_port}:${var.app_port} \
      -e ENVIRONMENT=${var.environment} \
      --log-driver=awslogs \
      --log-opt awslogs-region=$$REGION \
      --log-opt awslogs-group=/damolak-task/${var.environment} \
      --log-opt awslogs-stream=app \
      ${var.ecr_image_uri}
    EOF

  tags = {
    Name        = "${var.environment}-app"
    Environment = var.environment
  }
}
