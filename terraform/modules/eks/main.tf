module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_groups = {
    default = {
        desired_size = 2
        max_size     = 3
        min_size     = 1

        instance_types = ["t3.small"]

        ami_type      = "AL2_x86_64"
        capacity_type = "ON_DEMAND"
        disk_size     = 20
    }
}
}
