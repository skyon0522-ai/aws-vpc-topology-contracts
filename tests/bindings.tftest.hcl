# Inspect actual upstream resources in each mode; mock only computed IDs.
mock_provider "aws" {}

variables {
  name                    = "topology-contracts"
  region                  = "eu-west-1"
  cidr                    = "10.42.0.0/16"
  azs                     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnets          = ["10.42.0.0/24", "10.42.1.0/24", "10.42.2.0/24"]
  private_subnets         = ["10.42.10.0/24", "10.42.11.0/24", "10.42.12.0/24", "10.42.13.0/24", "10.42.14.0/24", "10.42.15.0/24"]
  intra_subnets           = ["10.42.20.0/24", "10.42.21.0/24", "10.42.22.0/24"]
  map_public_ip_on_launch = false
}

override_resource {
  target = aws_subnet.public[0]
  values = { id = "subnet-public-0" }
}

override_resource {
  target = aws_subnet.public[1]
  values = { id = "subnet-public-1" }
}

override_resource {
  target = aws_subnet.public[2]
  values = { id = "subnet-public-2" }
}

override_resource {
  target = aws_subnet.private[0]
  values = { id = "subnet-private-0" }
}

override_resource {
  target = aws_subnet.private[1]
  values = { id = "subnet-private-1" }
}

override_resource {
  target = aws_subnet.private[2]
  values = { id = "subnet-private-2" }
}

override_resource {
  target = aws_subnet.private[3]
  values = { id = "subnet-private-3" }
}

override_resource {
  target = aws_subnet.private[4]
  values = { id = "subnet-private-4" }
}

override_resource {
  target = aws_subnet.private[5]
  values = { id = "subnet-private-5" }
}

override_resource {
  target = aws_subnet.intra[0]
  values = { id = "subnet-intra-0" }
}

override_resource {
  target = aws_subnet.intra[1]
  values = { id = "subnet-intra-1" }
}

override_resource {
  target = aws_subnet.intra[2]
  values = { id = "subnet-intra-2" }
}

override_resource {
  target = aws_route_table.public[0]
  values = { id = "rtb-public-0" }
}

override_resource {
  target = aws_route_table.intra[0]
  values = { id = "rtb-intra-0" }
}

override_resource {
  target = aws_internet_gateway.this[0]
  values = { id = "igw-0" }
}


run "disabled_bindings" {
  command = plan
  plan_options { refresh = false }
  module { source = "./upstream" }
  variables {
    enable_nat_gateway     = false
    single_nat_gateway     = false
    one_nat_gateway_per_az = true
  }

  override_resource {
    target = aws_route_table.private[0]
    values = { id = "rtb-private-0" }
  }

  override_resource {
    target = aws_route_table.private[1]
    values = { id = "rtb-private-1" }
  }

  override_resource {
    target = aws_route_table.private[2]
    values = { id = "rtb-private-2" }
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route.private_nat_gateway) == 0 && length(aws_route_table.private) == 3
    error_message = "disabled: actual NAT, NAT-route and private-table cardinalities changed."
  }

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 6 && length(aws_subnet.intra) == 3 && length(aws_route_table_association.private) == 6
    error_message = "disabled: subnet or private-association cardinality changed."
  }

  assert {
    condition     = output.public_subnets == aws_subnet.public[*].id && output.private_subnets == aws_subnet.private[*].id && output.intra_subnets == aws_subnet.intra[*].id && output.private_route_table_ids == aws_route_table.private[*].id && output.natgw_ids == aws_nat_gateway.this[*].id && output.private_nat_gateway_route_ids == aws_route.private_nat_gateway[*].id
    error_message = "disabled: upstream output IDs must come from the actual resources."
  }

  assert {
    condition     = alltrue([for i, association in aws_route_table_association.private : association.subnet_id == aws_subnet.private[i].id && association.route_table_id == aws_route_table.private[[0, 1, 2, 0, 1, 2][i]].id])
    error_message = "disabled: private subnet association must use its intended private route table."
  }

  assert {
    condition     = alltrue([for i, subnet in aws_subnet.private : subnet.availability_zone == ["eu-west-1a", "eu-west-1b", "eu-west-1c", "eu-west-1a", "eu-west-1b", "eu-west-1c"][i]])
    error_message = "disabled: private subnet placement changed."
  }

  assert {
    condition     = alltrue([for subnet in concat(aws_subnet.private, aws_subnet.intra) : subnet.map_public_ip_on_launch != true])
    error_message = "disabled: private and intra subnets must not enable automatic public IPs."
  }

  assert {
    condition     = length(aws_route.public_internet_gateway) == 1 && aws_route.public_internet_gateway[0].destination_cidr_block == "0.0.0.0/0" && aws_route.public_internet_gateway[0].gateway_id == aws_internet_gateway.this[0].id && aws_route.public_internet_gateway[0].route_table_id == aws_route_table.public[0].id && !contains(aws_route_table.private[*].id, aws_route.public_internet_gateway[0].route_table_id) && !contains(aws_route_table.intra[*].id, aws_route.public_internet_gateway[0].route_table_id)
    error_message = "disabled: the public default route must use the IGW and a separate public route table."
  }

  assert {
    condition     = length(aws_route_table_association.public) == 3 && alltrue([for i, association in aws_route_table_association.public : association.subnet_id == aws_subnet.public[i].id && association.route_table_id == aws_route_table.public[0].id]) && length(aws_route_table_association.intra) == 3 && alltrue([for i, association in aws_route_table_association.intra : association.subnet_id == aws_subnet.intra[i].id && association.route_table_id == aws_route_table.intra[0].id])
    error_message = "disabled: public and intra associations must stay in their respective route tables."
  }

}


run "shared_bindings" {
  command = plan
  plan_options { refresh = false }
  module { source = "./upstream" }
  variables {
    enable_nat_gateway     = true
    single_nat_gateway     = true
    one_nat_gateway_per_az = false
  }

  override_resource {
    target = aws_route_table.private[0]
    values = { id = "rtb-private-0" }
  }

  override_resource {
    target = aws_nat_gateway.this[0]
    values = { id = "nat-0" }
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route.private_nat_gateway) == 1 && length(aws_route_table.private) == 1
    error_message = "shared: actual NAT, NAT-route and private-table cardinalities changed."
  }

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 6 && length(aws_subnet.intra) == 3 && length(aws_route_table_association.private) == 6
    error_message = "shared: subnet or private-association cardinality changed."
  }

  assert {
    condition     = output.public_subnets == aws_subnet.public[*].id && output.private_subnets == aws_subnet.private[*].id && output.intra_subnets == aws_subnet.intra[*].id && output.private_route_table_ids == aws_route_table.private[*].id && output.natgw_ids == aws_nat_gateway.this[*].id && output.private_nat_gateway_route_ids == aws_route.private_nat_gateway[*].id
    error_message = "shared: upstream output IDs must come from the actual resources."
  }

  assert {
    condition     = alltrue([for i, association in aws_route_table_association.private : association.subnet_id == aws_subnet.private[i].id && association.route_table_id == aws_route_table.private[[0, 0, 0, 0, 0, 0][i]].id])
    error_message = "shared: private subnet association must use its intended private route table."
  }

  assert {
    condition     = alltrue([for i, subnet in aws_subnet.private : subnet.availability_zone == ["eu-west-1a", "eu-west-1b", "eu-west-1c", "eu-west-1a", "eu-west-1b", "eu-west-1c"][i]])
    error_message = "shared: private subnet placement changed."
  }

  assert {
    condition     = alltrue([for subnet in concat(aws_subnet.private, aws_subnet.intra) : subnet.map_public_ip_on_launch != true])
    error_message = "shared: private and intra subnets must not enable automatic public IPs."
  }

  assert {
    condition     = length(aws_route.public_internet_gateway) == 1 && aws_route.public_internet_gateway[0].destination_cidr_block == "0.0.0.0/0" && aws_route.public_internet_gateway[0].gateway_id == aws_internet_gateway.this[0].id && aws_route.public_internet_gateway[0].route_table_id == aws_route_table.public[0].id && !contains(aws_route_table.private[*].id, aws_route.public_internet_gateway[0].route_table_id) && !contains(aws_route_table.intra[*].id, aws_route.public_internet_gateway[0].route_table_id)
    error_message = "shared: the public default route must use the IGW and a separate public route table."
  }

  assert {
    condition     = length(aws_route_table_association.public) == 3 && alltrue([for i, association in aws_route_table_association.public : association.subnet_id == aws_subnet.public[i].id && association.route_table_id == aws_route_table.public[0].id]) && length(aws_route_table_association.intra) == 3 && alltrue([for i, association in aws_route_table_association.intra : association.subnet_id == aws_subnet.intra[i].id && association.route_table_id == aws_route_table.intra[0].id])
    error_message = "shared: public and intra associations must stay in their respective route tables."
  }

  assert {
    condition     = alltrue([for i, route in aws_route.private_nat_gateway : route.destination_cidr_block == "0.0.0.0/0" && route.nat_gateway_id == aws_nat_gateway.this[i].id && route.route_table_id == aws_route_table.private[i].id && route.route_table_id != aws_route_table.public[0].id && route.route_table_id != aws_route_table.intra[0].id])
    error_message = "shared: private NAT default route must bind its corresponding NAT and private route table."
  }

  assert {
    condition     = alltrue([for i, nat in aws_nat_gateway.this : nat.subnet_id == aws_subnet.public[i].id])
    error_message = "shared: NAT must be placed in the corresponding public subnet."
  }

}


run "per_az_bindings" {
  command = plan
  plan_options { refresh = false }
  module { source = "./upstream" }
  variables {
    enable_nat_gateway     = true
    single_nat_gateway     = false
    one_nat_gateway_per_az = true
  }

  override_resource {
    target = aws_route_table.private[0]
    values = { id = "rtb-private-0" }
  }

  override_resource {
    target = aws_route_table.private[1]
    values = { id = "rtb-private-1" }
  }

  override_resource {
    target = aws_route_table.private[2]
    values = { id = "rtb-private-2" }
  }

  override_resource {
    target = aws_nat_gateway.this[0]
    values = { id = "nat-0" }
  }

  override_resource {
    target = aws_nat_gateway.this[1]
    values = { id = "nat-1" }
  }

  override_resource {
    target = aws_nat_gateway.this[2]
    values = { id = "nat-2" }
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3 && length(aws_route.private_nat_gateway) == 3 && length(aws_route_table.private) == 3
    error_message = "per_az: actual NAT, NAT-route and private-table cardinalities changed."
  }

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 6 && length(aws_subnet.intra) == 3 && length(aws_route_table_association.private) == 6
    error_message = "per_az: subnet or private-association cardinality changed."
  }

  assert {
    condition     = output.public_subnets == aws_subnet.public[*].id && output.private_subnets == aws_subnet.private[*].id && output.intra_subnets == aws_subnet.intra[*].id && output.private_route_table_ids == aws_route_table.private[*].id && output.natgw_ids == aws_nat_gateway.this[*].id && output.private_nat_gateway_route_ids == aws_route.private_nat_gateway[*].id
    error_message = "per_az: upstream output IDs must come from the actual resources."
  }

  assert {
    condition     = alltrue([for i, association in aws_route_table_association.private : association.subnet_id == aws_subnet.private[i].id && association.route_table_id == aws_route_table.private[[0, 1, 2, 0, 1, 2][i]].id])
    error_message = "per_az: private subnet association must use its intended private route table."
  }

  assert {
    condition     = alltrue([for i, subnet in aws_subnet.private : subnet.availability_zone == ["eu-west-1a", "eu-west-1b", "eu-west-1c", "eu-west-1a", "eu-west-1b", "eu-west-1c"][i]])
    error_message = "per_az: private subnet placement changed."
  }

  assert {
    condition     = alltrue([for subnet in concat(aws_subnet.private, aws_subnet.intra) : subnet.map_public_ip_on_launch != true])
    error_message = "per_az: private and intra subnets must not enable automatic public IPs."
  }

  assert {
    condition     = length(aws_route.public_internet_gateway) == 1 && aws_route.public_internet_gateway[0].destination_cidr_block == "0.0.0.0/0" && aws_route.public_internet_gateway[0].gateway_id == aws_internet_gateway.this[0].id && aws_route.public_internet_gateway[0].route_table_id == aws_route_table.public[0].id && !contains(aws_route_table.private[*].id, aws_route.public_internet_gateway[0].route_table_id) && !contains(aws_route_table.intra[*].id, aws_route.public_internet_gateway[0].route_table_id)
    error_message = "per_az: the public default route must use the IGW and a separate public route table."
  }

  assert {
    condition     = length(aws_route_table_association.public) == 3 && alltrue([for i, association in aws_route_table_association.public : association.subnet_id == aws_subnet.public[i].id && association.route_table_id == aws_route_table.public[0].id]) && length(aws_route_table_association.intra) == 3 && alltrue([for i, association in aws_route_table_association.intra : association.subnet_id == aws_subnet.intra[i].id && association.route_table_id == aws_route_table.intra[0].id])
    error_message = "per_az: public and intra associations must stay in their respective route tables."
  }

  assert {
    condition     = alltrue([for i, route in aws_route.private_nat_gateway : route.destination_cidr_block == "0.0.0.0/0" && route.nat_gateway_id == aws_nat_gateway.this[i].id && route.route_table_id == aws_route_table.private[i].id && route.route_table_id != aws_route_table.public[0].id && route.route_table_id != aws_route_table.intra[0].id])
    error_message = "per_az: private NAT default route must bind its corresponding NAT and private route table."
  }

  assert {
    condition     = alltrue([for i, nat in aws_nat_gateway.this : nat.subnet_id == aws_subnet.public[i].id])
    error_message = "per_az: NAT must be placed in the corresponding public subnet."
  }

  assert {
    condition     = alltrue([for i, subnet in aws_subnet.private : aws_subnet.public[[0, 1, 2, 0, 1, 2][i]].availability_zone == subnet.availability_zone && aws_nat_gateway.this[[0, 1, 2, 0, 1, 2][i]].subnet_id == aws_subnet.public[[0, 1, 2, 0, 1, 2][i]].id && aws_route.private_nat_gateway[[0, 1, 2, 0, 1, 2][i]].route_table_id == aws_route_table_association.private[i].route_table_id])
    error_message = "per_az: each private subnet must reach a NAT placed in its own AZ through its associated route table."
  }

}
