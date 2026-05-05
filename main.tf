# ================================================================
# ORCHESTRATION ROOT
# ================================================================

module "vpc" {
  source                = "./modules/vpc"
  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones    = var.availability_zones
  aws_region            = var.aws_region
}

module "security_groups" {
  source       = "./modules/security_groups"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
}

module "nacl" {
  source                = "./modules/nacl"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  database_subnet_ids   = module.vpc.database_subnet_ids
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  environment  = var.environment
}

module "endpoints" {
  source             = "./modules/endpoints"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  endpoint_sg_id     = module.security_groups.endpoint_sg_id
  aws_region         = var.aws_region
}

module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

module "compute" {
  source               = "./modules/compute"
  project_name         = var.project_name
  environment          = var.environment
  instance_type        = var.instance_type
  private_subnet_ids   = module.vpc.private_subnet_ids
  app_sg_id            = module.security_groups.app_sg_id
  iam_instance_profile = module.iam.instance_profile_name
  target_group_arn     = module.alb.target_group_arn
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
  depends_on           = [module.endpoints]
}

module "monitoring" {
  source                  = "./modules/monitoring"
  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  alert_email             = var.alert_email
  vpc_id                  = module.vpc.vpc_id
}
