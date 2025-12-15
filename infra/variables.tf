variable "region" {
  description = "AWS Deployment region.."
  default     = "us-east-1"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The VPC id for infrastructure"
  type        = string
}

variable "application_port" {
  description = "The port for the application"
  type        = string
  default     = "8080"
}
variable "application_subnet_ids" {
  description = "The subnet ids for the application"
  type        = list(string)
}
variable "application_image" {
  description = "The image for the application"
  type        = string
}
variable "application_env_vars" {
  description = "The environment variables for the application"
  type        = map(string)
  default     = {}
}
variable "application_env_secrets" {
  description = "The environment secrets for the application"
  type        = map(string)
  default     = {}
}
variable "application_desired_count" {
  description = "The desired count for the application"
  type        = number
  default     = 1
}
variable "application_max_count" {
  description = "The max count for the application"
  type        = number
  default     = 1
}

variable "log_retention_in_days" {
  description = "The number of days to retain log events in the CloudWatch log group"
  type        = number
  default     = 30
}
