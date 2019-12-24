output "website_url" {
  value = "http://${aws_s3_bucket.bucket.website_endpoint}"
}
# http://account-request-form-649774341977.s3-website-us-west-2.amazonaws.com