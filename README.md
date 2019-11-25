<!--
:type: service
:name: HashiCorp Consul
:icon: /_docs/consul.png
:description: Deploy a Consul cluster. Supports automatic bootstrapping, DNS, Consul UI, and auto healing.
:category: Service discovery, service mesh
:cloud: aws
:tags: consul, mesh
:license: gruntwork
:built-with: terraform, bash
-->


# Consul AWS Module

[![Maintained by Gruntwork.io](https://img.shields.io/badge/maintained%20by-gruntwork.io-%235849a6.svg)](https://gruntwork.io/?ref=repo_terraform_aws_consul)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.0-blue.svg)

This repo contains a Module for running Kubernetes clusters on [AWS](https://aws.amazon.com) using [Elastic Kubernetes Service (EKS)](https://docs.aws.amazon.com/eks/latest/userguide/clusters.html) with [Terraform](https://www.terraform.io).

![Terraform AWS  Consul](https://raw.githubusercontent.com/hashicorp/terraform-aws-consul/master/_docs/architecture.png)


# Consul AWS Module



## Features
* Secure service communication and observe communication between your services without modifying their code.
* Automate load balancer.
* Provides any number of health checks.
* Multi-Data centers out of the box.



## Learn

This repo is maintained by [Gruntwork](https://www.gruntwork.io), and follows the same patterns as [the Gruntwork Infrastructure as Code Library](https://gruntwork.io/infrastructure-as-code-library/), a collection of reusable, battle-tested, production ready infrastructure code. You can read [How to use the Gruntwork Infrastructure as Code Library](https://gruntwork.io/guides/foundations/how-to-use-gruntwork-infrastructure-as-code-library/) for an overview of how to use modules maintained by Gruntwork!

## Core concepts

* Consul Use Cases: overview of various use cases that consul is optimized for.
  * [Service Discovery](https://www.consul.io/discovery.html)

  * [Service Mesh](https://www.consul.io/mesh.html)

* [Consul Guides](https://learn.hashicorp.com/consul?utm_source=consul.io&utm_medium=docs&utm_content=top-nav): official guide on how to use Consul service to discover services and secure network traffic.

## Repo organization

* [modules](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules): the main implementation code for this repo, broken down into multiple standalone, orthogonal submodules.
* [examples](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples): This folder shows examples of different ways to combine the modules in the `modules` folder to deploy Consul.
* [test](https://github.com/hashicorp/terraform-aws-consul/tree/master/test): Automated tests for the modules and examples.
* [root](https://github.com/hashicorp/terraform-aws-consul/tree/master): The root folder is *an example* of how to use the [consul-cluster module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/consul-cluster) module to deploy a [Consul](https://www.consul.io/) cluster in [AWS](https://aws.amazon.com/). The Terraform Registry requires the root of every repo to contain Terraform code, so we've put one of the examples there. This example is great for learning and experimenting, but for production use, please use the underlying modules in the [modules folder](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules) directly.


## Deploy

### Non-production deployment (quick start for learning)
If you just want to try this repo out for experimenting and learning, check out the following resources:

* [examples folder](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples): The `examples` folder contains sample code optimized for learning, experimenting, and testing (but not production usage).

### Production deployment

To deploy Consul servers for production using this repo:

1. Create a Consul AMI using a Packer template that references the [install-consul module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-consul).
   Here is an [example Packer template](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/consul-ami#quick-start). 
   
   If you are just experimenting with this Module, you may find it more convenient to use one of our official public AMIs:
   - [Latest Ubuntu 16 AMIs](https://github.com/hashicorp/terraform-aws-consul/tree/master/_docs/ubuntu16-ami-list.md).
   - [Latest Amazon Linux 2 AMIs](https://github.com/hashicorp/terraform-aws-consul/master/_docs/amazon-linux-ami-list.md).
  
    **WARNING! Do NOT use these AMIs in your production setup. In production, you should build your own AMIs in your own 
    AWS account.**
   
1. Deploy that AMI across an Auto Scaling Group using the Terraform link:/modules/consul-cluster[consul-cluster module] 
   and execute the link:/modules/run-consul[run-consul script] with the `--server` flag during boot on each 
   Instance in the Auto Scaling Group to form the Consul cluster. Here is an example [Terraform configuration](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples/root-example#quick-start) to provision a Consul cluster.

To deploy Consul clients for production using this repo:
 
1. Use the [install-consul module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-consul) to install Consul alongside your application code.
1. Before booting your app, execute the [run-consul script](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/run-consul) with `--client` flag.
1. Your app can now use the local Consul agent for service discovery and key/value storage.
1. Optionally, you can use the [install-dnsmasq module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-dnsmasq) for Ubuntu 16.04 and Amazon Linux 2 or [setup-systemd-resolved](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/setup-systemd-resolved) for Ubuntu 18.04 to configure Consul as the DNS for a
   specific domain (e.g. `.consul`) so that URLs such as `foo.service.consul` resolve automatically to the IP 
   address(es) for a service `foo` registered in Consul (all other domain names will be continue to resolve using the
   default resolver on the OS).

## Support
If you need help with this repo or anything else related to infrastructure or DevOps, Gruntwork offers [Commercial Support](https://gruntwork.io/support/) via Slack, email, and phone/video. If you're already a Gruntwork customer, hop on Slack and ask away! If not, [subscribe now](https://www.gruntwork.io/pricing/). If you're not sure, feel free to email us at [support@gruntwork.io](mailto:support@gruntwork.io).


## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/hashicorp/terraform-aws-consul/tree/master/CONTRIBUTING.md) for instructions.


## License

Please see [LICENSE](LICENSE) for details on how the code in this repo is licensed.

Copyright &copy; 2019 Gruntwork, Inc.