provider "aws" {
  region = "ap-southeast-2"
  alias  = "aws_syd"
}

provider "aws" {
  region = "us-east-1"
  alias = "aws_us1"
}

provider "random" {
  alias = "rnd"
}