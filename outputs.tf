output "ingest_mode" {
  value = var.ingest_mode
}

output "srt_ingest_endpoints" {
  description = "Where the encoder sends SRT (caller mode, destination IP:port)."
  value = var.ingest_mode == "flow" ? [
    for f in awscc_mediaconnect_flow.this : "srt://${f.source.ingest_ip}:${var.srt_port}"
    ] : [
    "srt://${aws_cloudformation_stack.router[0].outputs["RouterInputIp"]}:${var.srt_port}"
  ]
}

output "flow_arns" {
  value = [for f in awscc_mediaconnect_flow.this : f.flow_arn]
}

output "router_input_arn" {
  value = var.ingest_mode == "router" ? aws_cloudformation_stack.router[0].outputs["RouterInputArn"] : null
}

output "router_output_arns" {
  value = var.ingest_mode == "router" ? [
    for i in range(local.pipeline_count) : aws_cloudformation_stack.router[0].outputs["RouterOutput${i}Arn"]
  ] : []
}

output "medialive_channel_id" {
  value = aws_medialive_channel.this.channel_id
}

output "playback_hls" {
  description = "HLS playback URL through CloudFront."
  value       = "https://${aws_cloudfront_distribution.this.domain_name}/out/v1/${awscc_mediapackagev2_channel_group.this.channel_group_name}/${awscc_mediapackagev2_channel.this.channel_name}/${awscc_mediapackagev2_origin_endpoint.cmaf.origin_endpoint_name}/index.m3u8"
}

output "playback_dash" {
  description = "DASH playback URL through CloudFront."
  value       = "https://${aws_cloudfront_distribution.this.domain_name}/out/v1/${awscc_mediapackagev2_channel_group.this.channel_group_name}/${awscc_mediapackagev2_channel.this.channel_name}/${awscc_mediapackagev2_origin_endpoint.cmaf.origin_endpoint_name}/index.mpd"
}

output "region" {
  value = var.region
}
