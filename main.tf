terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

## авторизация через профиль в aws cli
provider "aws" {
  profile = "default"
  region  = "us-east-1"

  assume_role {
# заменить role_Arn на актуальный
    role_arn = "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"
  }
}

## авторизация напрямую в iAWS provider
# provider "aws" {
#   region  = "us-east-1"
#   access_key = "access_key"
#   secret_key = "secret-key"

#   assume_role {
# заменить role_Arn на актуальный
#     role_arn = "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"
#   }
# }

/*
 * Create groups
 */
module "iam_group_students" {
  source = "./modules/iam-group-with-policies"
  name = var.group

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess"
  ]
}


/*
 * Create users
 */
resource "aws_iam_user" "iam_user" {
  for_each      = toset(var.iam_users)
  name          = each.key
  force_destroy = true
}

/*
 * Attach IAM users to groups
 */

resource "aws_iam_group_membership" "groups_users" {
  depends_on = [aws_iam_user.iam_user]

  name  = "usergroups"
  users = var.iam_users
  group = var.group
  
}


/*
 * Add IAM console access to users
 */
resource "aws_iam_user_login_profile" "console_access" {
  depends_on = [aws_iam_user.iam_user]
  for_each      = var.create_login_profiles == true ? toset(var.iam_users) : []
  user          = each.key
  pgp_key = var.pgp_key
  password_reset_required = true

}
resource "aws_iam_access_key" "programmatic_access" {
  depends_on = [aws_iam_user.iam_user]
  for_each      = var.create_access_keys == true ? toset(var.iam_users) : []

  user    = each.key
  pgp_key = var.pgp_key
}


