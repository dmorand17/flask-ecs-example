## State Management

This project uses an S3 bucket for Terraform state management. Before running Terraform, you need to create an S3 bucket and DynamoDB table for state locking.

1. Create an S3 bucket for Terraform state:

```bash
BUCKET_NAME="your-terraform-state-bucket"
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region us-east-1
```

2. Enable versioning on the S3 bucket:

```bash
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled
```

Replace `your-terraform-state-bucket` with your actual bucket name.

## Usage

1. Initialize Terraform with backend configuration:

```bash
terraform init
```

OR using a backend config

```bash
terraform init -backend-config=envs/<env>/backend.config
```

2. Review the planned changes:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply
```

# Infrastructure

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.23 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.26.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_express_gateway_service.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_express_gateway_service) | resource |
| [aws_iam_role.ecs_infrastructure_role_for_express_services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_infrastructure_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_application_desired_count"></a> [application\_desired\_count](#input\_application\_desired\_count) | The desired count for the application | `number` | `1` | no |
| <a name="input_application_env_secrets"></a> [application\_env\_secrets](#input\_application\_env\_secrets) | The environment secrets for the application | `map(string)` | `{}` | no |
| <a name="input_application_env_vars"></a> [application\_env\_vars](#input\_application\_env\_vars) | The environment variables for the application | `map(string)` | `{}` | no |
| <a name="input_application_image"></a> [application\_image](#input\_application\_image) | The image for the application | `string` | n/a | yes |
| <a name="input_application_max_count"></a> [application\_max\_count](#input\_application\_max\_count) | The max count for the application | `number` | `1` | no |
| <a name="input_application_port"></a> [application\_port](#input\_application\_port) | The port for the application | `string` | `"8080"` | no |
| <a name="input_application_subnet_ids"></a> [application\_subnet\_ids](#input\_application\_subnet\_ids) | The subnet ids for the application | `list(string)` | n/a | yes |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | The number of days to retain log events in the CloudWatch log group | `number` | `30` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Deployment region.. | `string` | `"us-east-1"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC id for infrastructure | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
