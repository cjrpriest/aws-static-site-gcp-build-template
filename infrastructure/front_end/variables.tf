variable "website_host" {
  type        = "string"
  description = "The host that we want to publish to"
}

variable "environment" {
  type = "string"
}

variable "hosted_zone_id" {
  type = "string"
}

variable "use_cdn" {
  type = "string"
}

variable "acm_certificate_arn" {
  type = "string"
}
