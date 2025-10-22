terraform {
  backend "s3" {
    bucket = "rocci-ihk-terraformstate"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

locals {
  common_tags = {
    Project     = "rocci-ihk"
    Environment = "dev"
    Owner       = "silvio"
  }
}

resource "aws_vpc" "rocci" {
  cidr_block           = "172.40.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.common_tags
}

resource "aws_internet_gateway" "ig-rocci" {
  vpc_id = aws_vpc.rocci.id
  tags   = local.common_tags
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.rocci.id
  cidr_block              = "172.40.10.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags                    = local.common_tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.rocci.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig-rocci.id
  }

  tags = local.common_tags
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.rocci.id
  cidr_block        = "172.40.0.0/24"
  availability_zone = "eu-central-1a"
  tags              = local.common_tags
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.rocci.id
  cidr_block        = "172.40.1.0/24"
  availability_zone = "eu-central-1b"
  tags              = local.common_tags
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.rocci.id
  cidr_block        = "172.40.2.0/24"
  availability_zone = "eu-central-1c"
  tags              = local.common_tags
}

resource "aws_db_subnet_group" "aurora" {
  name       = "aurora-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]

  tags = local.common_tags
}

resource "aws_security_group" "sg-eb-rocci" {
  name   = "eb-sg"
  vpc_id = aws_vpc.rocci.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

  tags = local.common_tags
}

variable "github_actions_ips" {
  default = [
    "20.201.28.0/23",
    "20.205.243.128/25",
    "20.207.73.0/25",
    "20.233.54.0/23",
  ]
}

resource "aws_security_group" "sg-aurora-rocci" {
  name   = "aurora-sg"
  vpc_id = aws_vpc.rocci.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-eb-rocci.id]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.github_actions_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_rds_cluster" "aurora-db" {
  cluster_identifier      = "rocci-ihk-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.08.2"
  engine_mode             = "provisioned"
  database_name           = "urlaub_app"
  master_username         = "admin"
  master_password         = "12345678"
  backup_retention_period = 5
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [aws_security_group.sg-aurora-rocci.id]
  storage_encrypted       = true
  deletion_protection     = false
  serverlessv2_scaling_configuration {
    min_capacity = 2
    max_capacity = 4
  }
  skip_final_snapshot   = true
  enable_http_endpoint  = true
  tags                  = local.common_tags
}

resource "aws_rds_cluster_instance" "aurora-db-instance" {
  identifier         = "rocci-ihk-instance-1"
  cluster_identifier = aws_rds_cluster.aurora-db.cluster_identifier
  engine             = aws_rds_cluster.aurora-db.engine
  engine_version     = aws_rds_cluster.aurora-db.engine_version
  instance_class     = "db.serverless"
  publicly_accessible = true
  tags               = local.common_tags
}

resource "aws_elastic_beanstalk_application" "app" {
  name = "rocci-aws-app"
  tags = local.common_tags
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = "rocci-aws-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.6.5 running Node.js 22"

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role-silvio"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role-silvio"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.rocci.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.public_a.id
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.sg-eb-rocci.id
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_rds_cluster.aurora-db.endpoint
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_NAME"
    value     = "urlaub_app"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USER"
    value     = aws_rds_cluster.aurora-db.master_username
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = aws_rds_cluster.aurora-db.master_password
  }

  tags = local.common_tags
}

output "db_host" {
  value = aws_rds_cluster.aurora-db.endpoint
}

output "db_user" {
  value = aws_rds_cluster.aurora-db.master_username
}

output "db_name" {
  value = aws_rds_cluster.aurora-db.database_name
}
