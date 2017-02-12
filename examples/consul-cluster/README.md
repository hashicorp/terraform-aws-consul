# Consul Cluster Example

This folder shows an example of Terraform code that uses the [consul-cluster](/modules/consul-cluster) module to deploy 
a Consul cluster on [AWS](https://aws.amazon.com/). This example expects you to create an [Amazon Machine Image 
(AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) that has Consul installed, which you can do using
the [consul-ami example](/examples/consul-ami)).  

For more info on how the Consul cluster works, check out the [consul-cluster](/modules/consul-cluster) documentation.

## Quick start

To deploy a Consul Cluster:

1. Create a Consul AMI. See the [consul-ami example](/examples/consul-ami) documentation for instructions.
1. Install [Terraform](https://www.terraform.io/).
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

Once the `apply` command finishes, it will output the IP addresses of the servers in your Consul cluster.