module "eks" {

	source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
	
	cluster_name = var.cluster_name
  cluster_version = "1.34"

   # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true
  
  # EKS Auto Mode
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
  
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = var.cluster_name
  }

}
