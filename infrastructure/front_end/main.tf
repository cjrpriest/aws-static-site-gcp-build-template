resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.website_host}-logs"
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket" "static_site" {
  bucket        = "${var.website_host}"
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"

    //    error_document = "error.html"
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_bucket.id}"
    target_prefix = "origin/"
  }
}

locals {
  origin_id = "${var.environment}-origin"
}

resource "aws_route53_record" "route53_record" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.website_host}"
  type    = "A"

  alias {
    # The join() hack is required because currently the ternary operator
    # evaluates the expressions on both branches of the condition before
    # returning a value. When not using a CDN, the aws_cloudfront_distribution.s3_distribution
    # resource gets a count of zero which triggers an evaluation error.
    # see https://github.com/hashicorp/terraform/issues/11566
    name = "${var.use_cdn ?
                    join(" ", aws_cloudfront_distribution.s3_distribution.*.domain_name) :
                    aws_s3_bucket.static_site.website_domain}"

    zone_id = "${var.use_cdn ?
                    join(" ", aws_cloudfront_distribution.s3_distribution.*.hosted_zone_id) :
                    aws_s3_bucket.static_site.hosted_zone_id}"

    evaluate_target_health = false
  }
}

# aws_cloudfront_distribution.s3_distribution.domain_name
# aws_cloudfront_distribution.s3_distribution.hosted_zone_id

resource "aws_cloudfront_distribution" "s3_distribution" {
  count = "${var.use_cdn ? 1 : 0}"

  origin {
    domain_name = "${aws_s3_bucket.static_site.bucket_regional_domain_name}"
    origin_id   = "${local.origin_id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.website_host}"
  default_root_object = "index.html"

  aliases = ["${var.website_host}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 300                 // 5m
    max_ttl                = 3600                // 1h
  }

  logging_config {
    include_cookies = true
    bucket          = "${aws_s3_bucket.log_bucket.id}.s3.amazonaws.com"
    prefix          = "cdn/"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags {
    environment = "${var.environment}"
  }

  viewer_certificate {
    acm_certificate_arn      = "${var.acm_certificate_arn}"
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method       = "sni-only"
  }
}
