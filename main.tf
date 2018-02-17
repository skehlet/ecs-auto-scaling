terraform {
  backend "s3" {
    # region, bucket, key, and dynamodb_table are provided via ./init.sh
  }
}

provider "aws" {
  region = "${var.region}"
}
