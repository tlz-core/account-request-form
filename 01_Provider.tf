# Configure the AWS Provider
provider "aws" {
  region     = "${var.AWSRegion}"
}

provider "aws" {
  alias = "use1"
  region = "us-east-1"
}
