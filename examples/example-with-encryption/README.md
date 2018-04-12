# Consul cluster with encryption example

This folder contains a set of Terraform manifest for deploying a Consul cluster in AWS, including a Packer manifest that creates an AMI a set of insecured certs for TLS validation, as well as installing an updated version of the `run-consul` script that accepts parameters for enabling RPC and gossip encryption.

The resulting AMI id can then be passed as a parameter to `variables.tf`. The `enable_gossip_encryption` and `enable_rpc_encryption` variables are set to `true` by default in this example, but they don't have to be in your implementation. In this example they're passed as parameters to the `user_data` template to generate the flags passed to `run-consul` but you can use a different strategy.

The end result of this example should be a cluster of 3 Consul servers and 3 Consul clients, all running on individual EC2 instances. If the default variables are used, both gossip and RPC encryption will be enabled. You can validate this by trying to bring up another Consul node or cluster NOT running with encryption and attempt to join the existing cluster.

Running this example with encryption turned off and then attempt to upgrade it to use encryption is a good exercise to validate that a production cluster can be upgraded with minimal impact.

To understand more about how Consul handles encryption or how you can upgrade to use encryption without downtime, check out the [Consul encryption documentation](https://www.consul.io/docs/agent/encryption.html). **IMPORTANT:** The certs included in this repo are **NOT** meant to be used in production. You should generate your own certs if you're running this for anything other than experimenting or testing.

## Quick start

To deploy a Consul cluster with encryption enabled:

1. Create a new AMI using the Packer manifest and the certificates in the `packer` directory.
1. Modify `main.tf` to add your provider credentials, VPC/subnet ids if you need to, etc.
1. Modify `variables.tf` to customize the cluster. **NOTE:** the `gossip_encryption_key` variable must be a 16-byte key that can be generated offline with `consul keygen`. It's **NOT** a good idea to keep this key **in plain text** in source control. It should be encrypted beforehand (with something like KMS) and decrypted by Consul during boot.
1. Run `terraform init`.
1. Run `terraform apply`.
1. `ssh` into one of the boxes and make sure all nodes correctly discover each other (by running `consul members` for example).
1. You can also validate that encryption is turned on by looking at `/opt/consul/log/consul-stdout.log` and verifying you see `Encrypt: Gossip: true, TLS-Outgoing: true, TLS-Incoming: true`.