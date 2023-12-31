variable "be_secrets" {
  description = "Secrets for be"
  type        = map(string)
}


variable "acm_arn" {
  description = "ACM arn for api domain"
  type        = string
}

variable "mongodb_atlas_endpoint" {
  description = "Atlas Endpoint Service to the mongodb atlas serverless db"
  type        = string
}
