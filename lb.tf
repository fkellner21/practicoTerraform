resource "aws_security_group" "aws-sg-load-balancer" {
  description = "Allow incoming connections for load balancer"
  vpc_id      = aws_vpc.app_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP connections"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-sg-alb"
  }
}

resource "aws_lb" "aws-application_load_balancer" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.aws-sg-load-balancer.id]
  subnets            = aws_subnet.public_subnets[*].id
  enable_deletion_protection = false

  tags = {
    Name = "terraform-alb"
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_vpc.id

  health_check {
    enabled             = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "terraform-alb-tg"
  }
}

resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.aws-application_load_balancers.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.id
  }
}

resource "aws_alb_target_group_attachment" "tgattachment" {
  count            = length(aws_instance.web[*].id)
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = element(aws_instance.web[*].id, count.index)
}

output "lb-dns" {
  value = aws_lb.aws-application_load_balancer.dns_name
}