resource "aws_cloudwatch_log_group" "laravel" {
  name = "/ecs/laravel"

  tags = {
    Environment = "production"
    Application = "laravel"
  }
}

resource "aws_cloudwatch_log_group" "mysql" {
  name = "/ecs/mysql"

  tags = {
    Environment = "production"
    Application = "mysql"
  }
}

resource "aws_ecs_task_definition" "laravel-main" {
  family                   = "my_laravel_test-main"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
#   container_definitions    = data.template_file.testapp.rendered
   container_definitions    = <<TASK_DEFINITION
   [
    {
      "dnsSearchDomains": null,
      "environmentFiles": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "/ecs/laravel",
          "awslogs-region": "ap-south-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "entryPoint": null,
      "portMappings": [
        {
          "hostPort": 80,
          "protocol": "tcp",
          "containerPort": 80
        }
      ],
      "command": null,
      "linuxParameters": null,
      "cpu": 0,
      "environment": [
        {
          "name": "APP_DEBUG",
          "value": "true"
        },
        {
          "name": "APP_ENV",
          "value": "local"
        },
        {
          "name": "APP_KEY",
          "value": "base64:tLmYfUrrZITzLIkSjFnV+PCAFxkdU+duUxjVSIlrrHo="
        },
        {
          "name": "APP_LOCALE",
          "value": "en"
        },
        {
          "name": "DB_CONNECTION",
          "value": "mysql"
        },
        {
          "name": "APP_URL",
          "value": "http://${module.mahesh-alb.elb-dns-name}"
        },
        {
          "name": "MAIL_ENV_ENCRYPTION",
          "value": "tcp"
        },
        {
          "name": "MAIL_ENV_FROM_ADDR",
          "value": "youremail@yourdomain.com"
        },
        {
          "name": "MAIL_ENV_FROM_NAME",
          "value": "Your Full Email Name"
        },
        {
          "name": "MAIL_ENV_PASSWORD",
          "value": "your_email_password"
        },
        {
          "name": "MAIL_ENV_USERNAME",
          "value": "your_email_username"
        },
        {
          "name": "MAIL_PORT_587_TCP_ADDR",
          "value": "smtp.whatever.com"
        },
        {
          "name": "MAIL_PORT_587_TCP_PORT",
          "value": "587"
        },
        {
          "name": "DB_DATABASE",
          "value": "question_board"
        },
        {
          "name": "MYSQL_PASSWORD",
          "value": "YOUR_laravel_USER_PASSWORD"
        },
        {
          "name": "MYSQL_PORT_3306_TCP_ADDR",
          "value": "example.laravel.terraform.com"
        },
        {
          "name": "DB_PORT",
          "value": "3306"
        },
        {
          "name": "DB_PASSWORD",
          "value": "YOUR_SUPER_SECRET_PASSWORD"
        },
        {
          "name": "DB_USERNAME",
          "value": "laravel"
        },
        {
          "name": "PHP_UPLOAD_LIMIT",
          "value": "100"
        }
      ],
      "resourceRequirements": null,
      "ulimits": null,
      "dnsServers": null,
      "mountPoints": [
        {
          "readOnly": null,
          "containerPath": "/var/lib/laravel",
          "sourceVolume": "laravel-vol"
        }
      ],
      "workingDirectory": null,
      "secrets": null,
      "dockerSecurityOptions": null,
      "memory": null,
      "memoryReservation": null,
      "volumesFrom": [],
      "stopTimeout": null,
      "image": "${data.aws_ecr_repository.example.repository_url}:${data.external.current_image.result["image_tag"]}",
      "startTimeout": null,
      "firelensConfiguration": null,
      "dependsOn": null,
      "disableNetworking": null,
      "interactive": null,
      "healthCheck": null,
      "essential": true,
      "links": [],
      "hostname": null,
      "extraHosts": null,
      "pseudoTerminal": null,
      "user": null,
      "readonlyRootFilesystem": null,
      "dockerLabels": null,
      "systemControls": null,
      "privileged": null,
      "name": "testapp"
    }
  ]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    
  }
   volume {
    name      = "laravel-vol"
    # host_path = "/ecs/service-storage"
  }
}



resource "aws_ecs_service" "test-service-laravel-main" {
  name            = "testapp-service-laravel-main"
  cluster         = aws_ecs_cluster.foo.id
  task_definition = aws_ecs_task_definition.laravel-main.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg-80.id]
    subnets          = data.aws_subnets.subnet.ids
    assign_public_ip = true
  }
    load_balancer {
    target_group_arn = module.mahesh-alb.elb-target-group-arn
    container_name   = "testapp"
    container_port   = 80
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role, aws_ecs_service.test-service-mysql]
}

data "aws_ecr_repository" "example" {
  name = "laravel"
}
# data "aws_ecr_image" "service_image" {
#   repository_name = "laravel"
#   image_tag = "master"
# }
# output "ecr_image" {
#   value = data.aws_ecr_image.service_image.image_tag
# }


data "external" "current_image" {
  program = ["bash", "./ecs-task-definition.sh"]
  # query = {
  #   app  = "testapp-service-laravel-main"
  #   cluster = "laravel-cluster"
  #   # path_root = "${jsonencode(path.root)}"
  # }
}
# output "get_new_tag" {
#   value = data.external.current_image.result["image_tag"]
# }