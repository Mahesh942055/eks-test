resource "aws_ecs_task_definition" "laravel-main" {
  family                   = "my_laravel_test-main"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
#   container_definitions    = data.template_file.testapp.rendered
   container_definitions    = jsonencode([
    {
      name  = "Laravel"
      image = "${data.aws_ecr_repository.example.repository_url}:${data.external.current_image.result["image_tag"]}",

      essential = true
      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
        }
      ]
      #secrets = local.secret
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/laravel",
          awslogs-region        = "ap-south-1",
          awslogs-stream-prefix = "app"
        }
      }
    },
    {
      name      = "nginx"
      image     = "114155856902.dkr.ecr.ap-south-1.amazonaws.com/nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/nginx",
          awslogs-region        = "ap-south-1",
          awslogs-stream-prefix = "nginx"
        }
      }
     }
    
  ])

}

#   runtime_platform {
#     operating_system_family = "LINUX"
    
#   }
#    volume {
#     name      = "laravel-vol"
#     # host_path = "/ecs/service-storage"
#   }
# }



resource "aws_ecs_service" "test-service-laravel-main" {
  name            = "testapp-service-laravel-main"
  cluster         = aws_ecs_cluster.foo.id
  task_definition = aws_ecs_task_definition.laravel-main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg-80.id]
    subnets          = data.aws_subnets.subnet.ids
    assign_public_ip = true
  }
    load_balancer {
    target_group_arn = module.mahesh-alb.elb-target-group-arn
    container_name   = "nginx"
    container_port   = 80
  }

  #depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role, aws_ecs_service.test-service-nginx]
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
