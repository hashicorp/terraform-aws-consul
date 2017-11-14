# Consul Cluster Example

This folder shows an example of Terraform code that uses the [consul-cluster](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/consul-cluster) module to deploy 
a [Consul](https://www.consul.io/) cluster in [AWS](https://aws.amazon.com/). The cluster consists of two Auto Scaling
Groups (ASGs): one with a small number of Consul server nodes, which are responsible for being part of the [consensus 
quorum](https://www.consul.io/docs/internals/consensus.html), and one with a larger number of client nodes, which 
would typically run alongside your apps:

![Consul architecture](https://github.com/hashicorp/terraform-aws-consul/blob/master/_docs/architecture.png?raw=true)

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Consul installed, which you can do using the [consul-ami example](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/consul-ami)). Note that to keep 
this example simple, both the server ASG and client ASG are running the exact same AMI. In real-world usage, you'd 
probably have multiple client ASGs, and each of those ASGs would run a different AMI that has the Consul agent 
installed alongside your apps.

For more info on how the Consul cluster works, check out the [consul-cluster](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/consul-cluster) documentation.



## Quick start

To deploy a Consul Cluster:

1. Build a Consul AMI. See the [consul-ami example](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/consul-ami) documentation for instructions. Make sure to
   note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Create your main.tf file and include the consul-cluster module as per example
```hcl
#demo consul cluster
module "consul_cluster" {
  # Use version v0.0.5 of the consul-cluster module (or check latest tags)
  source = "github.com/hashicorp/terraform-aws-consul//modules/consul-cluster?ref=v0.0.5"

  # Specify the ID of the Consul AMI. You should build this using the scripts in the install-consul module.
  ami_id = "ami-6820c012" # Ubuntu AMi, do not use in production. 
  instance_type = "t2.medium"
  cluster_name = "${var.cluster_name}"
  cluster_size = "${var.num_servers}"
  ssh_key_name = "${aws_key_pair.auth.key_name}"

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
  allowed_inbound_cidr_blocks = [ "0.0.0.0/0" ] # only use for testing, unsafe
  allowed_ssh_cidr_blocks = [ "0.0.0.0/0" ] # only use for testing, unsafe
  associate_public_ip_address = true
}
```
A full example is included [here](https://github.com/hashicorp/terraform-aws-consul/blob/master/examples/root-example/main.tf) with a minimal infrastructure included. 
Please notice this expects you have an RSA key set up in your .ssh folder, `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`.
This example is just for a demo, for production please refactor it following best practices.
1. If you need to customise it check [variables.tf](https://github.com/hashicorp/terraform-aws-consul/blob/master/modules/consul-cluster/variables.tf), as a reference for the 
	environment variables and their meaning.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
1. Run the [consul-examples-helper.sh script](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/consul-examples-helper/consul-examples-helper.sh) to 
   print out the IP addresses of the Consul servers and some example commands you can run to interact with the cluster:
   `../consul-examples-helper/consul-examples-helper.sh`. (notice you need consul and awscli installed)

