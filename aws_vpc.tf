module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${local.project}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]

  enable_nat_gateway     = true
  create_igw             = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  nat_gateway_tags = {
    Name = "${local.project}-nat-gateway"
  }
  nat_eip_tags = {
    Name = "${local.project}-nat-eip"
  }

  igw_tags = {
    Name = "${local.project}-igw"
  }

  default_vpc_enable_dns_support   = true
  default_vpc_enable_dns_hostnames = true
  enable_dns_support               = true
  enable_dns_hostnames             = true

  default_network_acl_tags    = { Name = "${local.project}-default" }
  default_route_table_tags    = { Name = "${local.project}-default" }
  default_security_group_tags = { Name = "${local.project}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.project}" = "shared"
    "kubernetes.io/role/elb"                 = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.project}" = "shared"
    "kubernetes.io/role/internal-elb"        = "1"
  }

  tags = local.tags
}

resource "aws_security_group" "vpce_sg" {
  name        = "mongo-vpce-sg"
  description = "Allow EKS node connect to MongoDB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow node connect to MongoDB"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [module.eks_blueprints.worker_node_security_group_id]
  }

  tags = merge(local.tags, {
    Name = "mongo-vpce"
  })
  depends_on = [
    module.eks_blueprints,
    module.eks_blueprints_kubernetes_addons
  ]
}

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "s3-vpc-endpoint" }
    },
    mongodb = {
      service_name       = var.mongodb_atlas_endpoint
      subnet_ids         = module.vpc.private_subnets
      security_group_ids = [aws_security_group.vpce_sg.id]
      tags               = { Name = "mongodb-vpc-endpoint" }
    }
  }

  tags       = local.tags
  depends_on = [aws_security_group.vpce_sg]
}
