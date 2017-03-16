# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A CONSUL CLUSTER IN AWS
# These templates show an example of how to use the consul-cluster module to deploy Consul in AWS. We deploy two Auto
# Scaling Groups (ASGs): one with a small number of Consul server nodes and one with a larger number of Consul client
# nodes. Note that these templates assume that the AMI you provide via the ami_id input variable is built from
# the examples/consul-ami/consul.json Packer template.
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = "${var.aws_region}"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "consul_servers" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/consul-aws-blueprint.git//modules/consul-cluster?ref=v0.0.1"
  source = "../../modules/consul-cluster"

  cluster_name  = "${var.cluster_name}-server"
  cluster_size  = "${var.num_servers}"
  instance_type = "t2.micro"

  # The EC2 Instances will use these tags to automatically discover each other and form a cluster
  cluster_tag_key   = "${var.cluster_tag_key}"
  cluster_tag_value = "${var.cluster_name}"

  ami_id    = "${var.ami_id}"
  user_data = "${data.template_file.user_data_server.rendered}"

  vpc_id             = "${data.aws_vpc.default.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = "${var.ssh_key_name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER EC2 INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_server" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_value = "${var.cluster_name}"
    server            = "true"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL CLIENT NODES
# Note that you do not have to use the consul-cluster module to deploy your clients. We do so simply because it
# provides a convenient way to deploy an Auto Scaling Group with the necessary IAM and security group permissions for
# Consul, but feel free to deploy those clients however you choose (e.g. a single EC2 Instance, a Docker cluster, etc).
# ---------------------------------------------------------------------------------------------------------------------

module "consul_clients" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/consul-aws-blueprint.git//modules/consul-cluster?ref=v0.0.1"
  source = "../../modules/consul-cluster"

  cluster_name  = "${var.cluster_name}-client"
  cluster_size  = "${var.num_clients}"
  instance_type = "t2.micro"

  cluster_tag_key   = "consul-clients"
  cluster_tag_value = "${var.cluster_name}"

  ami_id    = "${var.ami_id}"
  user_data = "${data.template_file.user_data_client.rendered}"

  vpc_id             = "${data.aws_vpc.default.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = "${var.ssh_key_name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH CONSUL CLIENT EC2 INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_client" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_value = "${var.cluster_name}"
    server            = "false"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY CONSUL IN THE DEFAULT VPC AND AVAILABILITY ZONES
# Using the default VPC and all availability zones makes this example easy to run and test, but in a production
# deployment, we strongly recommend deploying into a custom VPC and private subnets (the latter specified via the
# subnet_ids parameter in the consul-cluster module).
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "all" {}
