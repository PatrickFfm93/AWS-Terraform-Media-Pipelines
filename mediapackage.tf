# MediaPackage v2: channel group -> channel (two ingest endpoints) -> one CMAF origin
# endpoint serving HLS and DASH from the same segments.

resource "awscc_mediapackagev2_channel_group" "this" {
  channel_group_name = var.name
  description        = "Channel group for ${var.name}"
}

resource "awscc_mediapackagev2_channel" "this" {
  channel_group_name = awscc_mediapackagev2_channel_group.this.channel_group_name
  channel_name       = "${var.name}-channel"
  input_type         = "HLS"
  description        = "Fed by MediaLive channel ${var.name}-channel"
}

resource "awscc_mediapackagev2_origin_endpoint" "cmaf" {
  channel_group_name       = awscc_mediapackagev2_channel_group.this.channel_group_name
  channel_name             = awscc_mediapackagev2_channel.this.channel_name
  origin_endpoint_name     = "cmaf"
  container_type           = "CMAF"
  startover_window_seconds = var.startover_window_seconds

  segment = {
    segment_duration_seconds    = var.mediapackage_segment_seconds
    segment_name                = "segment"
    include_iframe_only_streams = false
  }

  hls_manifests = [{
    manifest_name                      = "index"
    child_manifest_name                = "child"
    manifest_window_seconds            = var.manifest_window_seconds
    program_date_time_interval_seconds = 60
  }]

  dash_manifests = [{
    manifest_name                        = "index"
    manifest_window_seconds              = var.manifest_window_seconds
    min_buffer_time_seconds              = 2 * var.mediapackage_segment_seconds
    min_update_period_seconds            = var.mediapackage_segment_seconds
    suggested_presentation_delay_seconds = 3 * var.mediapackage_segment_seconds
    segment_template_format              = "NUMBER_WITH_TIMELINE"
  }]
}

# Only the CloudFront distribution of this stack may read from the origin endpoint.
resource "awscc_mediapackagev2_origin_endpoint_policy" "cloudfront" {
  channel_group_name   = awscc_mediapackagev2_channel_group.this.channel_group_name
  channel_name         = awscc_mediapackagev2_channel.this.channel_name
  origin_endpoint_name = awscc_mediapackagev2_origin_endpoint.cmaf.origin_endpoint_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipal"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = ["mediapackagev2:GetObject", "mediapackagev2:GetHeadObject"]
      Resource  = awscc_mediapackagev2_origin_endpoint.cmaf.arn
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.this.arn }
      }
    }]
  })
}
