
data "aws_caller_identity" "current" {}

locals {
  bucket_name   = "${var.S3Bucket}-${data.aws_caller_identity.current.account_id}"
  whitelist_ips = "${module.ip_whitelist.cidr}"
  s3_origin_id  = "hostingbucketorigin"
  filesToHost=[
    "index.html",
    "error.html",
    "bootstrap.min.js",
    "bootstrap.min.css",
    "aws-sdk-2.7.16.min.js"
  ]
  vanity_name = "arf.${var.hosted_zone}"
}

//S3 Bucket to host upon
resource "aws_s3_bucket" "bucket" {
  count = "${local.bucket_name != "" ? 1 : 0}"

  bucket = "${var.add_vanity_url == "true" ? local.vanity_name : local.bucket_name}"
  acl    = "private"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["HEAD","GET","POST"]
    allowed_origins = ["http://${local.bucket_name}.s3-website.${var.AWSRegion}.amazonaws.com/*","${var.add_vanity_url == "true" ? "http://${local.vanity_name}/*" : ""}"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_policy" "bucketPolicy" {
  count = "${var.add_vanity_url == "true" ? "0" : "1"}"
  bucket = "${aws_s3_bucket.bucket.id}"

  policy = <<POLICY
{
      "Version":"2012-10-17",
      "Statement":[
          {
              "Sid":"IPReadGetObject",
              "Effect":"Allow",
              "Principal": {
                 "AWS": "*"
              },
              "Action":[
                  "s3:GetObject"
              ],
              "Resource":[
                  "arn:aws:s3:::${local.bucket_name}/*"
              ],
              "Condition": {
                  "IpAddress": {
                      "aws:SourceIp": ["${join(",", local.whitelist_ips)}"]
                  }
              }
          }
      ]
  }
POLICY
}


//APP.js template
data "template_file" "appJSTemplateFile" {
  template = "${file("app.js.tpl")}"

  vars {
    aws_region = "${var.AWSRegion}"
    identity_pool = "${aws_cognito_identity_pool.identPool.id}"
    bucket = "${aws_s3_bucket.bucket.id}"
    dynamoDBTable = "${var.dynamoDBTable}"
  }
}

//S3 Objects to HOST
resource "aws_s3_bucket_object" "hostedObject" {
  depends_on = ["aws_s3_bucket.bucket"]
  count= "${length(local.filesToHost)}"

  acl    = "private"
  content_type = "text/html"
  bucket = "${aws_s3_bucket.bucket.id}"
  key    = "${element(local.filesToHost, count.index)}"
  source ="${element(local.filesToHost, count.index)}"
  etag   = "${md5(file(element(local.filesToHost, count.index)))}"
}
resource "aws_s3_bucket_object" "appJS" {
  depends_on = ["aws_s3_bucket.bucket"]
  acl    = "private"
  content_type = "text/javascript"
  bucket = "${aws_s3_bucket.bucket.id}"
  key    = "app.js"
  content ="${data.template_file.appJSTemplateFile.rendered}"
}
