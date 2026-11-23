# Flow mode: one MediaConnect flow per MediaLive pipeline, each in its own AZ.
# Flows are created in STANDBY; scripts/start.sh starts them before the channel.

resource "aws_iam_role" "mediaconnect_secrets" {
  count = var.ingest_mode == "flow" && var.srt_passphrase_secret_arn != null ? 1 : 0
  name  = "${var.name}-mediaconnect-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "mediaconnect.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "mediaconnect_secrets" {
  count = length(aws_iam_role.mediaconnect_secrets)
  role  = aws_iam_role.mediaconnect_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = var.srt_passphrase_secret_arn
    }]
  })
}

resource "awscc_mediaconnect_flow" "this" {
  count             = var.ingest_mode == "flow" ? local.pipeline_count : 0
  name              = "${var.name}-flow-${count.index}"
  availability_zone = local.pipeline_azs[count.index]

  source = {
    name           = "srt-in-${count.index}"
    description    = "SRT contribution for pipeline ${count.index}"
    protocol       = "srt-listener"
    ingest_port    = var.srt_port
    min_latency    = var.srt_min_latency_ms
    whitelist_cidr = var.allowed_source_cidr

    decryption = var.srt_passphrase_secret_arn == null ? null : {
      algorithm  = "aes128"
      key_type   = "srt-password"
      role_arn   = aws_iam_role.mediaconnect_secrets[0].arn
      secret_arn = var.srt_passphrase_secret_arn
    }
  }

  source_monitoring_config = {
    thumbnail_state = "ENABLED"
  }
}

resource "aws_medialive_input" "flow" {
  count    = var.ingest_mode == "flow" ? 1 : 0
  name     = "${var.name}-input"
  type     = "MEDIACONNECT"
  role_arn = aws_iam_role.medialive.arn

  dynamic "media_connect_flows" {
    for_each = awscc_mediaconnect_flow.this
    content {
      flow_arn = media_connect_flows.value.flow_arn
    }
  }
}
