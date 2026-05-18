resource "aws_ecr_repository" "posts_api" {
  name         = "posts-api"
  force_delete = true
}