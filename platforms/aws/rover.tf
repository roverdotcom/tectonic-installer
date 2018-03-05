variable "resolved_domains" {
  type    = "list"
  default = []
}

variable "datadog_api_key" {
  default = ""
}

variable "google_oidc_client_id" {
  type    = "string"
  default = ""
}

variable "google_oidc_client_secret" {
  type    = "string"
  default = ""
}

variable "google_oidc_redirect_uri" {
  type    = "string"
  default = ""
}

variable "google_oidc_domain" {
  type    = "string"
  default = ""
}

variable "tectonic_aws_elb_subnet_ids" {
  type    = "list"
  default = []
}

variable "tectonic_aws_elb_ingress_cidr_blocks" {
  type    = "list"
  default = ["0.0.0.0/0"]
}
