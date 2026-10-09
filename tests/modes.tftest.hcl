mock_provider "aws" {}

run "disabled_by_default" {
  command = plan
  plan_options {
    refresh = false
  }

  assert {
    condition     = length(output.topology.nat_gateway_ids) == 0 && length(output.topology.private_nat_route_ids) == 0 && length(output.topology.private_route_table_ids) == 3
    error_message = "Disabled mode must omit NATs and their default routes while keeping three private route tables."
  }
  assert {
    condition     = length(output.topology.public_subnet_ids) == 3 && length(output.topology.private_subnet_ids) == 6 && length(output.topology.intra_subnet_ids) == 3
    error_message = "The example must expose the actual three-public, six-private, three-intra module outputs."
  }
}

run "shared" {
  command = plan
  plan_options {
    refresh = false
  }
  variables {
    nat_mode = "shared"
  }

  assert {
    condition     = length(output.topology.nat_gateway_ids) == 1 && length(output.topology.private_nat_route_ids) == 1 && length(output.topology.private_route_table_ids) == 1
    error_message = "Shared mode must expose one actual NAT, one NAT default route, and one private route table."
  }
}

run "per_az" {
  command = plan
  plan_options {
    refresh = false
  }
  variables {
    nat_mode = "per_az"
  }

  assert {
    condition     = length(output.topology.nat_gateway_ids) == 3 && length(output.topology.private_nat_route_ids) == 3 && length(output.topology.private_route_table_ids) == 3
    error_message = "Per-AZ mode must expose three actual NATs, three NAT default routes, and three private route tables."
  }
}

run "reject_unknown_nat_mode" {
  command = plan
  plan_options {
    refresh = false
  }
  variables {
    nat_mode = "per_subnet"
  }
  expect_failures = [var.nat_mode]
}
