output "trend_micro_aws_iam_role_arn" {
  description = "The role ARN for the AWS IAM role to connect to Deep Security Manager"
  value       = aws_iam_role.tmds_role.arn
}
