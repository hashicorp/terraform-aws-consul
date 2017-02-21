# Consul AMI

This folder shows an example of how to use the [install-consul](/modules/install-consul) module with 
[Packer](https://www.packer.io/) to create [Amazon Machine Images 
(AMIs)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) that have Consul installed on top of:
 
1. Ubuntu 16.04
1. Amazon Linux

These AMIs will have [Consul](https://www.consul.io/) installed and configured to automatically join a cluster during 
boot-up. To see how to deploy this AMI, check out the [consul-cluster example](/examples/consul-cluster). 

For more info on Consul installation and configuration, check out the 
[install-consul](/modules/install-consul) documentation.



## Quick start

To build the Consul AMI:

1. Install [Packer](https://www.packer.io/).
1. Configure your AWS credentials using one of the [options supported by the AWS 
   SDK](http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html). Usually, the easiest option is to
   set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.
1. Update the `variables` section of the `consul.json` Packer template to configure the region, base AMI IDs, and
   which versions of Consul and this blueprint you wish to use.
1. Run `packer build consul.json`.

When the build finishes, it will output the IDs of the new AMIs. To see how to deploy one of these AMIs, check out the 
[consul-cluster example](/examples/consul-cluster).