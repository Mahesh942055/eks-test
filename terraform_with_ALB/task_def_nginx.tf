data "aws_subnets" "subnet" {
  filter {
    name = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}
resource "aws_ecs_task_definition" "test" {
  family                   = "my_laravel_test-nginx"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = <<TASK_DEFINITION
[
      {
        "dnsSearchDomains": null,
        "environmentFiles": null,
        "logConfiguration": {
          "logDriver": "awslogs",
          "secretOptions": null,
          "options": {
            "awslogs-group": "/ecs/laravel-nginx",
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
            "value": "false"
          },
          {
            "name": "APP_ENV",
            "value": "production"
          },
          {
            "name": "APP_KEY",
            "value": "<<Fill in Later!>>"
          },
          {
            "name": "APP_LOCALE",
            "value": "en"
          },
          {
            "name": "APP_TIMEZONE",
            "value": "US/Pacific"
          },
          {
            "name": "APP_URL",
            "value": "http://127.0.0.1:YOUR_PORT_NUMBER"
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
            "name": "nginx_DATABASE",
            "value": "laravel"
          },
          {
            "name": "nginx_PASSWORD",
            "value": "YOUR_laravel_USER_PASSWORD"
          },
          {
            "name": "nginx_ROOT_PASSWORD",
            "value": "YOUR_SUPER_SECRET_PASSWORD"
          },
          {
            "name": "nginx_USER",
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
            "containerPath": "/var/lib/nginx",
            "sourceVolume": "laravelsql-vol"
          }
        ],
        "workingDirectory": null,
        "secrets": null,
        "dockerSecurityOptions": null,
        "memory": null,
        "memoryReservation": null,
        "volumesFrom": [],
        "stopTimeout": null,
        "image": "114155856902.dkr.ecr.ap-south-1.amazonaws.com/nginx:latest",
        "startTimeout": null,
        "firelensConfiguration": null,
        "dependsOn": null,
        "disableNetworking": null,
        "interactive": null,
        "healthCheck": null,
        "essential": true,
        "links": null,
        "hostname": null,
        "extraHosts": null,
        "pseudoTerminal": null,
        "user": null,
        "readonlyRootFilesystem": null,
        "dockerLabels": null,
        "systemControls": null,
        "privileged": null,
        "name": "laravel-nginx-con"
      }
    ]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    
  }
   volume {
    name      = "laravelsql-vol"
  }
}
resource "aws_ecs_service" "test-service-nginx" {
  name            = "testapp-service-laravel-nginx"
  cluster         = aws_ecs_cluster.foo.id
  task_definition = aws_ecs_task_definition.test.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg-3306.id]
    subnets          = data.aws_subnets.subnet.ids
    assign_public_ip = true
  }
  service_registries{
    registry_arn = aws_service_discovery_service.example.arn
  }
    load_balancer {
    target_group_arn = module.mahesh-alb.elb-target-group-arn
    container_name   = "laravel-nginx-con"
    container_port   = 80
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role, aws_service_discovery_service.example]
}

resource "aws_service_discovery_private_dns_namespace" "example" {
  name        = "laravel.terraform.com"
  description = "example"
  vpc         = aws_default_vpc.default.id
}

resource "aws_service_discovery_service" "example" {
  name = "example"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.example.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}