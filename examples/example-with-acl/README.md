# Consul cluster with ACL example

This folder contains a set of Terraform manifest for deploying a Consul cluster in AWS which has [ACL](https://www.consul.io/docs/security/acl) enabled. The root bootstrap token is stored in an [AWS Systems Manager Parameter](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) so that other nodes can retrieve it and create agent tokens for themselves.

The end result of this example should be a cluster of 3 Consul servers and 3 Consul clients, all running on individual EC2 instances.

## Quick start

To deploy a Consul cluster with ACL enabled:

1. Create a new AMI using the Packer manifest in the [`examples/consul-ami`](../consul-ami) directory. Make note of the resulting AMI ID as you will need that for step 3.
1. Modify `main.tf` to add your provider credentials, VPC/subnet ids if you need to, etc.
1. Modify `variables.tf` to customize the cluster. At a minimum you will want to supply the AMI ID from the image built in step 1.
1. Run `terraform init`.
1. Run `terraform apply`.
1. `ssh` into one of the boxes and make sure all nodes correctly discover each other (by running `consul members` for example).