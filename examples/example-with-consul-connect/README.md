# Consul Cluster with Connect service mesh

This folder shows an example of Terraform code that uses the [run-consul module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/consul-cluster) to deploy
a [Consul](https://www.consul.io/) cluster in [AWS](https://aws.amazon.com/) with the Consul Connect Service Mesh turned on. The cluster consists of 2 Services with
side-proxies and upstream dependencies between them.

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
that has Consul installed, which you can do using the [consul-ami example](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/consul-ami)). Note that to keep
this example simple, both the server ASG and client ASG are running the exact same AMI. In real-world usage, you'd
probably have multiple client ASGs, and each of those ASGs would run a different AMI that has the Consul agent
installed alongside your apps.

For more info on how the Consul cluster works, check out the [consul-cluster](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/consul-cluster) documentation.



## Quick start

To deploy a Consul Cluster:

1. `git clone` this repo to your computer.
1. Optional: build a Consul AMI. See the [consul-ami example](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/consul-ami) documentation for instructions. Make sure to
   note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default. If you built a custom AMI, put the AMI ID into the `ami_id` variable. Otherwise, one of our
   public example AMIs will be used by default. These AMIs are great for learning/experimenting, but are NOT
   recommended for production use.
1. Run `terraform init`.
1. Run `terraform apply`.
1. Run the [consul-examples-helper.sh script](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/consul-examples-helper/consul-examples-helper.sh) to
   print out the IP addresses of the Consul servers and some example commands you can run to interact with the cluster:
   `../consul-examples-helper/consul-examples-helper.sh`.
