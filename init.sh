#!/bin/bash
set -e

# You must create the s3 bucket and dynamodb table before running this.
account_id=$(aws sts get-caller-identity --output text --query Account)
my_name=ecs-autoscaling
region=us-west-2
s3_bucket=${account_id}-terraform-state-${region}
dynamodb_table=terraform-state

terraform init \
	-backend-config="region=${region}" \
	-backend-config="bucket=${s3_bucket}" \
	-backend-config="key=${my_name}.tfstate" \
    -backend-config="dynamodb_table=$dynamodb_table"
