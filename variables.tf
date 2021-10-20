variable "iam_users" {
  description = "List of iam users that that needs to be created"
  type = list(string)
}

variable "group" {
  type = string
}

variable "pgp_key" {
  type        = string
  description = "PGP key in plain text or using the format `keybase:username` to encrypt user keys and passwords"
  default     = null
}

variable "create_access_keys" {
  type        = bool
  description = "Set to true to create programmatic access for all users"
  default     = false
}

variable "create_login_profiles" {
  type        = bool
  description = "Set to true to create console access for all users"
  default     = false
}
