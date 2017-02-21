# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A CONSUL CLUSTER IN AWS
# These templates show an example of how to use the consul-cluster module to deploy Consul across an Auto Scaling 
# Group (ASG). Note that these templates assume that the AMI you provide via the ami_id input variable is built from
# the examples/consul-ami/consul.json Packer template.
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = "${var.aws_region}"
}

# ---------------------------------------------------------------------------------------------------------------------
# USE THE CONSUL-CLUSTER MODULE TO DEPLOY CONSUL ACROSS AN ASG
# ---------------------------------------------------------------------------------------------------------------------

module "consul" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/consul-aws-blueprint.git//modules/consul-cluster?ref=v0.0.1"
  source = "../../modules/consul-cluster"

  cluster_name = "${var.cluster_name}"
  cluster_size = "${var.cluster_size}"
  instance_type = "t2.micro"

  # The EC2 Instances will use these tags to automatically discover each other and form a cluster
  cluster_tag_key   = "${var.cluster_tag_key}"
  cluster_tag_value = "${var.cluster_name}"

  ami_id        = "${var.ami_id}"
  user_data     = "${data.template_file.user_data.rendered}"

  vpc_id             = "${data.aws_vpc.default.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  # To make testing easier, we are allowing requests from any IP address here, but in a production deployment, we
  # strongly recommend you limit this to the IP address ranges of known, trusted servers.
  ssh_key_name = "${var.ssh_key_name}"
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH EC2 INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    cluster_tag_key = "${var.cluster_tag_key}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY CONSUL IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC makes this example easy to run and test, but in a production deployment, we strongly recommend
# deploying into a custom VPC and private subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "all" {}
