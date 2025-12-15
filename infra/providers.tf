provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        managed-by = "terraform"
        project    = "flask-ecs-example"
      },
      var.additional_tags
    )
  }
}
