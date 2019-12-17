output "s3-endpoint" {
  value = "http://${aws_s3_bucket.emili-darder-website.website_endpoint}"
}
