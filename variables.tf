variable "S3Bucket" {
  type = "string"
  default = "account-request-form"
}

variable "account-request-whitelist-ips" {
  type = "list"
  default = ["199.47.246.1/24"]
  description = "Deprecated in favor of ip_whitelist module usage"
}
variable "AWSRegion" {
  type = "string"
  default = "us-east-2"
}

variable "dynamoDBTable" {
  type = "string"
  default ="OrgAccountRequest"
}

variable "add_vanity_url" {
  type = "string"
  default = "false"
  description = "When set to 'true' will attempt to make vanity_url of ``arf.${var.hosted_zone}``"
}

variable "hosted_zone" {
  type = "string"
  default = ""
  description = "MUST be defined when ``var.add_vanity_url`` = true"
}
