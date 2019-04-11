provider "aws" {
  region = "eu-west-1"
}

locals {
  environment_name = "${var.branch == "master" ? "prod" :
                        var.branch == "develop" ? "beta" : var.branch}"

  environment_host = "${local.environment_name == "prod" ? var.website_domain :
                        local.environment_name == "beta" ? format("beta.%s", var.website_domain) :
                        format("%s.environments.%s", local.environment_name, var.website_domain)}"
}

module "front_end" {
  source = "front_end"

  website_host        = "${local.environment_host}"
  hosted_zone_id      = "${var.hosted_zone_id}"
  environment         = "${local.environment_name}"
  use_cdn             = "${local.environment_name == "prod" || local.environment_name == "beta"}"
  acm_certificate_arn = "${var.acm_certificate_arn}"
}
