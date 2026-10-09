output "topology" {
  description = "Identifiers returned by the pinned upstream module, without a separate topology calculator."
  value = {
    public_subnet_ids        = module.vpc.public_subnets
    private_subnet_ids       = module.vpc.private_subnets
    intra_subnet_ids         = module.vpc.intra_subnets
    private_route_table_ids  = module.vpc.private_route_table_ids
    nat_gateway_ids          = module.vpc.natgw_ids
    private_nat_route_ids    = module.vpc.private_nat_gateway_route_ids
    public_internet_route_id = module.vpc.public_internet_gateway_route_id
    internet_gateway_id      = module.vpc.igw_id
  }
}
