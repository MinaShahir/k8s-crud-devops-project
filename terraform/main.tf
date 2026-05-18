module "vpc" {
  source = "./modules/vpc"
}

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id = module.vpc.vpc_id
}

module "iam" {
  source = "./modules/iam"
}

module "eks" {
  source = "./modules/eks"

  cluster_name = var.cluster_name

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

module "ecr" {
  source = "./modules/ecr"
}