data "aws_route53_zone" "zone" {
  count = "${var.add_vanity_url == "true" ? "1" : "0"}"
  name = "${var.hosted_zone}."
}

resource "aws_route53_record" "arf" {
  count = "${var.add_vanity_url == "true" ? "1" : "0"}"
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${local.vanity_name}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.www_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.www_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }

}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "arf website identity"
}

resource "aws_acm_certificate" "cert" {
  count = "${var.add_vanity_url == "true" ? "1" : "0"}"
  domain_name               = "${local.vanity_name}"
  validation_method         = "DNS"
  subject_alternative_names = ["*.${local.vanity_name}"]

  provider = "aws.use1"
}

resource "aws_route53_record" "acm_validation" {
  count = "${var.add_vanity_url == "true" ? "1" : "0"}"
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count = "${var.add_vanity_url == "true" ? "1" : "0"}"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.acm_validation.fqdn}"]

  timeouts {
    create = "70m"
  }
  provider = "aws.use1"
}

resource "aws_cloudfront_distribution" "www_distribution" {
  count = "${var.add_vanity_url == "true" ? "1" : "0"}"
  origin {
    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
    domain_name = "${aws_s3_bucket.bucket.bucket_domain_name}"
    origin_id   = "${local.vanity_name}"
  }

  enabled             = true
  default_root_object = "index.html"

  custom_error_response {
     error_code         = 403
     response_code      = 200
     response_page_path = "/error.html"
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    target_origin_id       = "${local.vanity_name}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["${local.vanity_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "AU", "FR"]
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.cert.arn}"
    ssl_support_method  = "sni-only"
  }

  web_acl_id = "${aws_waf_web_acl.waf_acl.id}"
}

resource "aws_s3_bucket_policy" "vanityBucketPolicy" {
  count = "${var.add_vanity_url == "true" ? "1" : "0"}"
  bucket = "${aws_s3_bucket.bucket.id}"

  policy = <<POLICY
{
  	"Version": "2012-10-17",
  	"Id": "Policy142469412148",
  	"Statement": [
  		{
  			"Sid": "Stmt1424694110324",
  			"Effect": "Allow",
  			"Principal": {
  				"AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
  			},
  			"Action": [
  				"s3:List*",
  				"s3:Get*"
  			],
  			"Resource": "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"
  		}
  	]
}
POLICY
}

module "ip_whitelist" {
  source  = "localterraform.com/TLZ-Demo/ip_whitelist/aws"
  version = "~> 0.0.1"
}

resource "aws_waf_ipset" "ipset" {
    name = "arf_ip-set_whitelist_public"
    ip_set_descriptors = ["${module.ip_whitelist.waf}"]
}

resource "aws_waf_rule" "wafrule" {
    depends_on  = ["aws_waf_ipset.ipset"]

    name        = "arfIpSetWhitelistRule"
    metric_name = "arfIpSetWhitelistRule"

    predicates {
        data_id = "${aws_waf_ipset.ipset.id}"
        negated = false
        type    = "IPMatch"
    }
}

resource "aws_waf_web_acl" "waf_acl" {
    depends_on  = ["aws_waf_ipset.ipset", "aws_waf_rule.wafrule"]

    name        = "arfWhitelistAcl"
    metric_name = "arfWhitelistAcl"

    default_action {
        type = "BLOCK"
    }

    rules {
        action {
            type = "ALLOW"
        }

        priority = 1
        rule_id  = "${aws_waf_rule.wafrule.id}"
        type     = "REGULAR"
    }
}
