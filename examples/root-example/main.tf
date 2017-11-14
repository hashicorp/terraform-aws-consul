provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret}"
  region     = "${var.region}"
}


resource "aws_key_pair" "consul_cluster_key_pair" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#demo consul cluster
module "consul_cluster" {
  # Use version v0.0.5 of the consul-cluster module
  source = "github.com/hashicorp/terraform-aws-consul//modules/consul-cluster?ref=v0.0.5"

  # Specify the ID of the Consul AMI. You should build this using the scripts in the install-consul module.
  ami_id = "ami-6820c012"
  instance_type = "t2.medium"
  # aws_region = "${var.region}"
  cluster_name = "${var.cluster_name}"
  # num_servers = "${var.num_servers}"
  cluster_size = "${var.num_servers}"
  ssh_key_name = "${aws_key_pair.consul_cluster_key_pair.key_name}"

  # Add this tag to each node in the cluster
  cluster_tag_key   = "demo-consul-cluster"
  cluster_tag_value = "demo-consul-cluster-example"

  # Configure and start Consul during boot. It will automatically form a cluster with all nodes that have that same tag.
  user_data = <<-EOF
              #!/bin/bash
              /opt/consul/bin/run-consul --server --cluster-tag-key demo-consul-cluster
              EOF

  # ... See variables.tf for the other parameters you must define for the consul-cluster module
  vpc_id = "${aws_vpc.vpc_consul_cluster.id}"
  subnet_ids = [ "${aws_subnet.subnet_consul_cluster.id}" ]
  allowed_inbound_cidr_blocks = [ "0.0.0.0/0" ]
  allowed_ssh_cidr_blocks = [ "0.0.0.0/0" ]
  associate_public_ip_address = true
}

#networking

# Create a VPC to launch our instances into
resource "aws_vpc" "vpc_consul_cluster" {
  tags {
    Name = "Consul Cluster VPC"
  }
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "gateway_consul_cluster" {
  tags {
    Name = "Consul Cluster Internet Gateway"
  }
  vpc_id = "${aws_vpc.vpc_consul_cluster.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "consul_cluster_internet_access" {
  route_table_id         = "${aws_vpc.vpc_consul_cluster.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gateway_consul_cluster.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "subnet_consul_cluster" {
  vpc_id                  = "${aws_vpc.vpc_consul_cluster.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "sec_group_consul_cluster" {
  name        = "demo Consul Cluster security"
  description = "Used for demo Consul Cluster"
  vpc_id      = "${aws_vpc.vpc_consul_cluster.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul Cluster Service access from anywhere
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul HTTP API access from anywhere
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "consul_cluster_network_interface" {
  subnet_id   = "${aws_subnet.subnet_consul_cluster.id}"
  private_ips = ["10.0.1.10"]
}