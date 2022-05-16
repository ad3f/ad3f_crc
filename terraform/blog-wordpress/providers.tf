#Use AWS as our deployment provider 

provider "aws" {
  region = var.region-main
  alias  = "aws-main"
}