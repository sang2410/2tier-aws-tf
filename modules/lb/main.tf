#create loadbalancer for webtier
resource "aws_lb" "public_alb" {
  name               = "${var.project_name}-publicalb"
  internal           = false
  load_balancer_type = "application" 
  security_groups    = [var.public_instance_security_group_id]   
  subnets            = [var.public_subnet_az1_id, var.public_subnet_az2_id]   

  tags = {
    name = "${var.project_name}-publicalb"
  }
}

#create listener on port 80 with redirect to 443
resource "aws_lb_listener" "alb_public_http_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# create a listener on port 443 with forward action
resource "aws_lb_listener" "alb_public_https_listener" {
  load_balancer_arn  = aws_lb.public_alb.arn
  port               = 443
  protocol           = "HTTPS"
  ssl_policy         = "ELBSecurityPolicy-2016-08"
  certificate_arn    =  var.aws_acm_certificate_validation_acm_certificate_validation_arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_public_target_group.arn
  }
}


#create target group for load balancer
resource "aws_lb_target_group" "alb_public_target_group" {
  name        = "${var.project_name}-pub-tg"
  port        = 80
  protocol    = "HTTP"    
  target_type = "instance" #"ip" for ALB/NLB, "instance" for autoscaling group, 
  vpc_id      = var.vpc_id

  tags        = {
    name = "${var.project_name}-tg"
  }

  depends_on  = [aws_lb.public_alb]

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled             = true
    interval            = 300
    path                = "/check.html"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}
