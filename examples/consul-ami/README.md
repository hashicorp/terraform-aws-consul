# Consul AMI

This folder shows an example of how to use the [consul-install-scripts](/modules/consul-install-scripts) with 
[Packer](https://www.packer.io/) to create a Consul [Amazon Machine Image 
(AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html). This AMI will have Consul installed and 
configured to automatically join a cluster during boot-up. To see how to deploy this AMI, check out the 
[consul-cluster example](/examples/consul-cluster). 

For more info on Consul installation and configuration, check out the 
[consul-install-scripts](/modules/consul-install-scripts) documentation.

## Quick start

To build the Consul AMI:

1. Install [Packer](https://www.packer.io/).
1. Configure your AWS credentials using one of the [options supported by the AWS 
   SDK](http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html). Usually, the easiest option is to
   set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.
1. Run `packer build consul.json`.

When the build finishes, it will output the ID of your new AMI. To see how to deploy this AMI, check out the 
[consul-cluster example](/examples/consul-cluster).