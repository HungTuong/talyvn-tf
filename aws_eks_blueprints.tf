#Cluster provisioning.
module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.0"

  cluster_name = local.project

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  # EKS CONTROL PLANE VARIABLES
  cluster_version     = local.cluster_version
  cluster_kms_key_arn = data.aws_kms_key.key.arn

  # List of map_users
  map_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${local.iam_name}" # The ARN of the IAM user to add.
      username = "opsuser"                                                                            # The user name within Kubernetes to map to the IAM role
      groups   = ["system:masters"]                                                                   # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
    }
  ]

  # EKS MANAGED NODE GROUPS
  node_security_group_additional_rules = {
    # ingress rules
    ingress_self_grafana = {
      description = "Allow grafana access within node groups"
      protocol    = "tcp"
      from_port   = 3000
      to_port     = 3000
      type        = "ingress"
      self        = true
    }

    ingress_self_prometheus_push_gw = {
      description = "Allow prometheus push gateways within node groups"
      protocol    = "tcp"
      from_port   = 9091
      to_port     = 9091
      type        = "ingress"
      self        = true
    }
    ingress_self_prometheus = {
      description = "Allow grafana access prometheus within node groups"
      protocol    = "tcp"
      from_port   = 9090
      to_port     = 9090
      type        = "ingress"
      self        = true
    }

    ingress_self_cost_metrics = {
      description = "Allow kubecost access cost metrics within node groups"
      protocol    = "tcp"
      from_port   = 9003
      to_port     = 9003
      type        = "ingress"
      self        = true
    }

    ingress_self_coredns_metrics = {
      description = "Allow prometheus access coredns within node groups"
      protocol    = "tcp"
      from_port   = 9153
      to_port     = 9153
      type        = "ingress"
      self        = true
    }

    ingress_self_kube_state_metrics = {
      description = "Allow prometheus access kube_state within node groups"
      protocol    = "tcp"
      from_port   = 8080
      to_port     = 8080
      type        = "ingress"
      self        = true
    }

    ingress_self_repo_server = {
      description = "Allow ArgoCD port within node groups"
      protocol    = "tcp"
      from_port   = 8081
      to_port     = 8081
      type        = "ingress"
      self        = true
    }

    ingress_self_redis_server = {
      description = "Allow ArgoCD port within node groups"
      protocol    = "tcp"
      from_port   = 6379
      to_port     = 6379
      type        = "ingress"
      self        = true
    }

    ingress_self_node_exporter_metrics = {
      description = "Allow prometheus access node exporter within node groups"
      protocol    = "tcp"
      from_port   = 9100
      to_port     = 9100
      type        = "ingress"
      self        = true
    }

    ingress_self_back_end = {
      description = "Allow BE access within node groups"
      protocol    = "tcp"
      from_port   = 5000
      to_port     = 5000
      type        = "ingress"
      self        = true
    }

    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller."
    }

    metrics_server_allow_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 4443
      to_port                       = 4443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to metrics server webhook"
    }

    ingress_allow_karpenter_webhook_access_from_control_plane = {
      description                   = "Allow access from control plane to webhook port of karpenter"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }

    # egress rules
    egress_to_mongodb = {
      description = "Node to mongoDB"
      protocol    = "tcp"
      from_port   = 27017
      to_port     = 27017
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress_self_repo_server = {
      description = "Allow ArgoCD port within node groups"
      protocol    = "tcp"
      from_port   = 8081
      to_port     = 8081
      type        = "egress"
      self        = true
    }

    egress_self_redis_server = {
      description = "Allow ArgoCD port within node groups"
      protocol    = "tcp"
      from_port   = 6379
      to_port     = 6379
      type        = "egress"
      self        = true
    }

    egress_self_coredns_metrics = {
      description = "Allow prometheus access coredns within node groups"
      protocol    = "tcp"
      from_port   = 9153
      to_port     = 9153
      type        = "egress"
      self        = true
    }

    egress_self_node_exporter_metrics = {
      description = "Allow prometheus access node exporter within node groups"
      protocol    = "tcp"
      from_port   = 9100
      to_port     = 9100
      type        = "egress"
      self        = true
    }

    egress_self_kube_state_metrics = {
      description = "Allow prometheus access kube_state within node groups"
      protocol    = "tcp"
      from_port   = 8080
      to_port     = 8080
      type        = "egress"
      self        = true
    }

    egress_self_cost_metrics = {
      description = "Allow kubecost access cost metrics within node groups"
      protocol    = "tcp"
      from_port   = 9003
      to_port     = 9003
      type        = "egress"
      self        = true
    }

    egress_self_prometheus = {
      description = "Allow grafana access prometheus within node groups"
      protocol    = "tcp"
      from_port   = 9090
      to_port     = 9090
      type        = "egress"
      self        = true
    }

    egress_self_prometheus_push_gw = {
      description = "Allow prometheus push gateways within node groups"
      protocol    = "tcp"
      from_port   = 9091
      to_port     = 9091
      type        = "egress"
      self        = true
    }
  }

  managed_node_groups = {
    #---------------------------------------------------------#
    # Bottlerocket instance type Worker Group
    #---------------------------------------------------------#
    # Checkout this doc https://github.com/bottlerocket-os/bottlerocket for configuring userdata for Launch Templates
    bottlerocket_x86 = {
      # 1> Node Group configuration - Part1
      node_group_name        = local.node_group_name # Max 40 characters for node group name
      create_launch_template = true                  # false will use the default launch template
      launch_template_os     = "bottlerocket"        # amazonlinux2eks or bottlerocket
      public_ip              = false                 # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;

      # 2> Node Group scaling configuration
      # desized and min >= 2 for karpenter
      desired_size = 2
      min_size     = 2
      max_size     = 2

      # 3> Node Group IAM policy configuration
      iam_role_additional_policies = {
        "ManagedEcr" : "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "ManagedSecrets" : "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
      }

      # 4> Node Group compute configuration
      ami_type       = "BOTTLEROCKET_x86_64"                                                              # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64
      capacity_type  = "SPOT"                                                                             # ON_DEMAND or SPOT
      instance_types = ["c6a.xlarge", "c5a.xlarge", "m5.xlarge", "m6i.xlarge", "m5a.xlarge", "m4.xlarge"] # List of instances to get capacity from multipe pools
      block_device_mappings = [
        {
          device_name = "/dev/xvda"
          volume_type = "gp3"
          volume_size = 5
          encrypted   = true
        },
        {
          device_name = "/dev/xvdb"
          volume_type = "gp3"
          volume_size = 20
          encrypted   = true
        }
      ]

      # 5> Node Group network configuration
      subnet_type = "private"
      subnet_ids  = module.vpc.private_subnets # Defaults to private subnet-ids used by EKS Controle plane. Define your private/public subnets list with comma separated subnet_ids  = ['subnet1','subnet2','subnet3']

      k8s_labels = {
        Environment = "prod"
        WorkerType  = "SPOT"
      }
      additional_tags = {
        Name        = "btl-x86-spot"
        subnet_type = "private"
      }
    }
  }

  platform_teams = {
    admin = {
      users = [
        data.aws_caller_identity.current.arn
      ]
    }
  }

  tags = local.tags
}
