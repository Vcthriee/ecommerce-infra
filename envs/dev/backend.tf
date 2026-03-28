

terraform {
  backend "s3" {
    bucket         = "cloudthrieesecurity-terraform-state"
    key            = "ecommerce/dev/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

#/J3e+WphQnREsFNHkhDX7fL7OUE9qWkglLJKxuKBDWfvN06SIe4YlVLjFoLnpRXt