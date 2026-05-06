output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}
