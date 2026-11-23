# CloudFront in front of MediaPackage v2, authenticated with origin access control.

data "aws_cloudfront_cache_policy" "mediapackage" {
  name = "Managed-Elemental-MediaPackage"
}

resource "aws_cloudfront_origin_access_control" "mediapackage" {
  name                              = "${var.name}-mediapackagev2"
  description                       = "OAC for MediaPackage v2 channel group ${var.name}"
  origin_access_control_origin_type = "mediapackagev2"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  comment         = "Live delivery for ${var.name}"
  price_class     = var.cloudfront_price_class
  is_ipv6_enabled = true
  http_version    = "http2and3"

  origin {
    origin_id                = "mediapackagev2"
    domain_name              = awscc_mediapackagev2_channel_group.this.egress_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.mediapackage.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "mediapackagev2"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.mediapackage.id
    compress               = false
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
