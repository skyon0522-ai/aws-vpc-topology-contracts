provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source = "./upstream"

  name   = "topology-contracts"
  region = "eu-west-1"
  cidr   = "10.42.0.0/16"
  azs    = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  public_subnets  = ["10.42.0.0/24", "10.42.1.0/24", "10.42.2.0/24"]
  private_subnets = ["10.42.10.0/24", "10.42.11.0/24", "10.42.12.0/24", "10.42.13.0/24", "10.42.14.0/24", "10.42.15.0/24"]
  intra_subnets   = ["10.42.20.0/24", "10.42.21.0/24", "10.42.22.0/24"]

  enable_nat_gateway      = var.nat_mode != "disabled"
  single_nat_gateway      = var.nat_mode == "shared"
  one_nat_gateway_per_az  = var.nat_mode != "shared"
  map_public_ip_on_launch = false
}
