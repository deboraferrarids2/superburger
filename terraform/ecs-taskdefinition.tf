data "aws_ecr_image" "latest" {
  repository_name = "apieventos"
  image_tag       = "latest"
}

data "aws_db_instance" "challengedb" {
  db_instance_identifier = "challengedb"
}

locals {
  secrets = [
    {
      name  = "AWS_ACCESS_KEY_ID"
      value = var.aws_access_key_id
    },
    {
      name  = "AWS_SECRET_ACCESS_KEY"
      value = var.aws_secret_access_key
    },
    {
      name  = "challengedb"
      value = "challengedb"
    },
    {
      name  = "DEBUG"
      value = "False"
    },
    {
      name  = "INTEGRATION_REFRESH_TOKEN_DURATION_SECONDS"
      value = "10800"
    },
    {
      name  = "INTEGRATION_TOKEN_DURATION_SECONDS"
      value = "3600"
    },
    {
      name  = "PG_HOST_L"
      value = var.pg_host_l
    },
    {
      name  = "PG_HOST_R1"
      value = var.pg_host_r1
    },
    {
      name  = "PG_PASS_L"
      value = var.pg_pass_l
    },
    {
      name  = "PG_PASS_R"
      value = var.pg_pass_r
    },
    {
      name  = "PG_USER_L"
      value = "fiap"
    },
    {
      name  = "PG_USER_R"
      value = "fiap"
    }
  ]
}

resource "aws_ecs_task_definition" "app" {
  family                   = "apieventos-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::778862303728:user/pipeline"
  task_role_arn            = "arn:aws:iam::778862303728:user/pipeline"
  container_definitions    = jsonencode(
    [
      {
        name      = "app"
        image     = "${data.aws_ecr_image.latest.repository_url}:${data.aws_ecr_image.latest.image_tag}"
        cpu       = 256
        memory    = 512
        essential = true
        portMappings = [
          {
            containerPort = 3000
            hostPort      = 3000
            protocol      = "tcp"
          }
        ]
        environment = []
        secrets     = local.secrets
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/app"
            awslogs-region        = "us-east-1"
            awslogs-stream-prefix = "ecs"
          }
        }
        # A aplicação será executada como no docker-compose
        command = ["bash", "-c", "python manage.py runserver 0.0.0.0:3000"]
      }
    ]
  )
}


resource "aws_ecs_task_definition" "migrate" {
  family                   = "apieventos-migration"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::778862303728:user/pipeline"
  task_role_arn            = "arn:aws:iam::778862303728:user/pipeline"
  container_definitions    = jsonencode(
    [
        {
        name      = "migration"
        image     = "${data.aws_ecr_image.latest.repository_url}:${data.aws_ecr_image.latest.image_tag}"
        cpu       = 256
        memory    = 512
        essential = true
        environment = [
            {
            name  = "DJANGO_SUPERUSER_USERNAME"
            value = "admin"
            },
            {
            name  = "DJANGO_SUPERUSER_PASSWORD"
            value = "admin"
            },
            {
            name  = "DJANGO_SUPERUSER_EMAIL"
            value = "admin@example.com"
            }
        ]
        command   = ["bash", "-c", "python manage.py makemigrations && python manage.py migrate && python manage.py createsuperuser --noinput && python manage.py populate_products"]
        logConfiguration = {
            logDriver = "awslogs"
            options = {
            awslogs-group         = "/ecs/migration"
            awslogs-region        = "us-east-1"
            awslogs-stream-prefix = "ecs"
            }
        }
    )
}


# CloudWatch log groups for application and migration containers
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "migration_logs" {
  name              = "/ecs/migration"
  retention_in_days = 7
}
