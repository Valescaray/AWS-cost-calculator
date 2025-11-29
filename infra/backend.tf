terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  backend "s3" {
    bucket         = "cloud-cost-calculator-tfstate-prod"
    key            = "cloud-cost-calculator/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "cloud-cost-calculator-tfstate-locks"
    encrypt        = true
  }
}