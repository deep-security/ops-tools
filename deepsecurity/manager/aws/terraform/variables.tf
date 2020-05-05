variable environment {
  description = "Available values:  dev, qa, prod."
}

variable service_name {
  default = "trend-micro-deep-security"
}

variable tmds_aws_account_id {
  description = "Account ID for Trend Micro Deep Security AWS"
  default = "147995105371"
}

variable external_id {
  description = "The External ID for assume role policy for cross account access"
}
