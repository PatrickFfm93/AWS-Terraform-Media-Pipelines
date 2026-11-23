# Route MediaLive and MediaConnect alerts to an SNS topic.

resource "aws_sns_topic" "alerts" {
  name = "${var.name}-live-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == null ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_event_rule" "media_alerts" {
  name        = "${var.name}-media-alerts"
  description = "MediaLive channel alerts and MediaConnect alerts for ${var.name}"

  event_pattern = jsonencode({
    source      = ["aws.medialive", "aws.mediaconnect"]
    detail-type = ["MediaLive Channel Alert", "MediaConnect Alert"]
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule = aws_cloudwatch_event_rule.media_alerts.name
  arn  = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.alerts.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.media_alerts.arn } }
    }]
  })
}
