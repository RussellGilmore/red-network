####################################################################################################
# VPC Flow Logs (only when enable_flow_logs is true)
####################################################################################################

locals {
  flow_logs_log_group_name = var.flow_logs_log_group_name != "" ? var.flow_logs_log_group_name : "/aws/vpc-flow-logs/${var.vpc_name}"
}

# CloudWatch log group that receives the flow log records
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = local.flow_logs_log_group_name
  retention_in_days = var.flow_logs_retention_days

  tags = merge(
    local.tags,
    {
      Name = "${var.vpc_name}-flow-logs"
    }
  )
}

# IAM role assumed by the VPC Flow Logs service to write to CloudWatch
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.vpc_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

# Permissions allowing the role to publish log events to the log group
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.vpc_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
      }
    ]
  })
}

# The flow log itself, attached to the VPC
resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.main.id
  traffic_type    = var.flow_logs_traffic_type
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(
    local.tags,
    {
      Name = "${var.vpc_name}-flow-log"
    }
  )
}
