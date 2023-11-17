variable "region" {}
variable "key_name" {}
variable "az" {}
variable "access_key" {}
variable "secret_key" {}
variable "volume_id" {} # not used at the moment - placeholder
variable "m_email" {}
variable "w_email" {}
variable "current_ami" {}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

### AMI ### use only if you want to update

# data "aws_ami" "bitnami-ami" {
#   most_recent = true
#   filter {
#     name   = "name"
#     values = ["bitnami-wordpress-*-linux-debian-*"]
#   }
#
#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }
#
# output "ami" {
#   value = data.aws_ami.bitnami-ami.id
# }

resource "aws_instance" "bitnami_instance" {
  ami = var.current_ami
  # ami                    = data.aws_ami.bitnami-ami.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  availability_zone      = var.az
  vpc_security_group_ids = [aws_security_group.ssh_security_group.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
    # this will be used for recovery 
    # if ec2 down -> create snapshot -> create ami from snapshot -> run new ec2 from ami
    delete_on_termination = false
    encrypted             = false
  }
}

resource "aws_eip" "elastic_ip" {
  instance = aws_instance.bitnami_instance.id
}

resource "aws_security_group" "ssh_security_group" {
  name        = "ssh-security-group"
  description = "Allow inbound SSH and all outbound traffic"

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
}

resource "aws_cloudwatch_metric_alarm" "status_check_alarm" {
  alarm_name          = "wordpress-ec2-status-check-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "1"

  dimensions = {
    InstanceId = aws_instance.bitnami_instance.id
  }

  alarm_description = "Alarm when status check failed"

  alarm_actions = [aws_sns_topic.alarms_topic.arn]
}

resource "aws_sns_topic" "alarms_topic" {
  name = "alarms-topic"
}

resource "aws_sns_topic_subscription" "alarms_topic_subscription_m" {
  topic_arn = aws_sns_topic.alarms_topic.arn
  protocol  = "email"
  endpoint  = var.m_email
}

resource "aws_sns_topic_subscription" "alarms_topic_subscription_w" {
  topic_arn = aws_sns_topic.alarms_topic.arn
  protocol  = "email"
  endpoint  = var.w_email
}


output "EIP" {
  value = aws_eip.elastic_ip.public_ip
}
