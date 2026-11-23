data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  tags = merge({
    Project   = var.name
    ManagedBy = "terraform"
    Stack     = "live-video-chain"
  }, var.extra_tags)

  pipeline_count = var.channel_class == "STANDARD" ? 2 : 1

  # One AZ per MediaLive pipeline; flows and router outputs follow the same AZs.
  pipeline_azs = slice(data.aws_availability_zones.available.names, 0, local.pipeline_count)

  medialive_input_id = (
    var.ingest_mode == "flow"
    ? aws_medialive_input.flow[0].id
    : aws_cloudformation_stack.router[0].outputs["MediaLiveInputId"]
  )

  mediapackage_ingest_urls = slice(awscc_mediapackagev2_channel.this.ingest_endpoint_urls, 0, local.pipeline_count)
}
