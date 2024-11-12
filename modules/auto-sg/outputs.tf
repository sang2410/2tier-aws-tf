output "public_launch_arn"{
    value = aws_launch_template.public_launch_template.arn
}

output "public_launch_id"{
    value = aws_launch_template.public_launch_template.id
}
