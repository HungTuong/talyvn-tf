locals {
  project         = "thesis"
  iam_name        = "hungt.iam"
  region          = data.aws_region.current.name
  cluster_version = "1.26"
  namespace       = "default"
  node_group_name = "btl-x86"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  #---------------------------------------------------------------
  # ADD-ON APPLICATION
  #---------------------------------------------------------------

  cluster_s3_sa          = "s3-sa"
  cluster_secretstore_sa = "secrets-store-csi-sa"
  cluster_sa             = "cluster-sa"
  karpenter_sa           = "karpenter"
  addon_application = {
    path               = "chart"
    repo_url           = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
    add_on_application = true
  }
  domain = "talyvn.com"

  waf = {
    # the priority in waf will be referenced to the order of the rules in the list
    managed_rules = [
      "AWSManagedRulesCommonRuleSet",
      "AWSManagedRulesSQLiRuleSet",
      "AWSManagedRulesLinuxRuleSet",
      "AWSManagedRulesKnownBadInputsRuleSet",
      "AWSManagedRulesAmazonIpReputationList",
      "AWSManagedRulesAnonymousIpList"
    ]
  }
  tags = {
    Terraform   = "True"
    Environment = "dev"
  }
}
