
## To deploy Consul servers for production using this repo:


1. Create a Consul AMI using a Packer template that references the [install-consul module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-consul).
   Here is an [example Packer template](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/consul-ami#quick-start). 
   
   If you are just experimenting with this Module, you may find it more convenient to use one of our official public AMIs:
   - [Latest Ubuntu 16 AMIs](https://github.com/hashicorp/terraform-aws-consul/tree/master/_docs/ubuntu16-ami-list.md).
   - [Latest Amazon Linux 2 AMIs](https://github.com/hashicorp/terraform-aws-consul/master/_docs/amazon-linux-ami-list.md).
  
    **WARNING! Do NOT use these AMIs in your production setup. In production, you should build your own AMIs in your own 
    AWS account.**
   
2. Deploy that AMI across an Auto Scaling Group using the Terraform [consul-cluster module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/consul-cluster)
   and execute the [run-consul script](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/run-consul) with the `--server` flag during boot on each 
   Instance in the Auto Scaling Group to form the Consul cluster. Here is an example [Terraform configuration](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/root-example#quick-start) to provision a Consul cluster.

## To deploy Consul clients for production using this repo:
 
1. Use the [install-consul module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-consul) to install Consul alongside your application code.
1. Before booting your app, execute the [run-consul script](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/run-consul) with `--client` flag.
1. Your app can now use the local Consul agent for service discovery and key/value storage.
1. Optionally, you can use the [install-dnsmasq module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-dnsmasq) for Ubuntu 16.04 and Amazon Linux 2 or [setup-systemd-resolved](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/setup-systemd-resolved) for Ubuntu 18.04 to configure Consul as the DNS for a
   specific domain (e.g. `.consul`) so that URLs such as `foo.service.consul` resolve automatically to the IP 
   address(es) for a service `foo` registered in Consul (all other domain names will be continue to resolve using the
   default resolver on the OS).
