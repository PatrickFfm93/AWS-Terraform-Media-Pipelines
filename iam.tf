# Role MediaLive assumes to attach to MediaConnect flows, write logs and read parameters.

resource "aws_iam_role" "medialive" {
  name = "${var.name}-medialive"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "medialive.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "medialive" {
  role = aws_iam_role.medialive.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ManageFlowOutputs"
        Effect   = "Allow"
        Action   = ["mediaconnect:ManagedDescribeFlow", "mediaconnect:ManagedAddOutput", "mediaconnect:ManagedRemoveOutput"]
        Resource = "*"
      },
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams", "logs:DescribeLogGroups"]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:ElementalMediaLive:*"
      },
      {
        Sid      = "Parameters"
        Effect   = "Allow"
        Action   = ["ssm:GetParameters", "ssm:GetParameter", "ssm:DescribeParameters"]
        Resource = "*"
      }
    ]
  })
}
