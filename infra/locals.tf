locals {
  # Get the AccountId
  account_id    = data.aws_caller_identity.current.account_id
  account_alias = data.aws_iam_account_alias.current.account_alias
  region        = data.aws_region.current.name
  partition     = data.aws_partition.current.partition
}
