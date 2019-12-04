<!--
:type: service
:name: HashiCorp Consul
:icon: /_docs/consul.png
:description: Deploy a Consul cluster. Supports automatic bootstrapping, DNS, Consul UI, and auto healing.
:category: Service discovery, service mesh
:cloud: aws
:tags: consul, mesh
:license: open-source
:built-with: terraform, bash
-->


# Consul AWS Module

[![Maintained by Gruntwork.io](https://img.shields.io/badge/maintained%20by-gruntwork.io-%235849a6.svg)](https://gruntwork.io/?ref=repo_terraform_aws_consul)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.0-blue.svg)

This repo contains a set of modules in the [modules folder](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules) for deploying a [Consul](https://www.consul.io/) cluster on [AWS](https://aws.amazon.com/) using [Terraform](https://www.terraform.io/). Consul is a distributed, highly-available tool that you can use for service discovery and key/value storage. A Consul cluster typically includes a small number of server nodes, which are responsible for being part of the [consensus quorum](https://www.consul.io/docs/internals/consensus.html), and a larger number of client nodes, which you typically run alongside your apps:

![Terraform AWS  Consul](https://raw.githubusercontent.com/hashicorp/terraform-aws-consul/master/_docs/architecture.png)


# Consul AWS Module



## Features
* Deploy Consul servers and agents
* Automatic bootstrapping
* Auto healing
* Auto DNS configuration
* Consul UI



## Learn

This repo is maintained by [Gruntwork](https://www.gruntwork.io), and follows the same patterns as [the Gruntwork Infrastructure as Code Library](https://gruntwork.io/infrastructure-as-code-library/), a collection of reusable, battle-tested, production ready infrastructure code. You can read [How to use the Gruntwork Infrastructure as Code Library](https://gruntwork.io/guides/foundations/how-to-use-gruntwork-infrastructure-as-code-library/) for an overview of how to use modules maintained by Gruntwork!

## Core concepts

* Consul Use Cases: overview of various use cases that consul is optimized for.
  * [Service Discovery](https://www.consul.io/discovery.html)

  * [Service Mesh](https://www.consul.io/mesh.html)

* [Consul Guides](https://learn.hashicorp.com/consul?utm_source=consul.io&utm_medium=docs&utm_content=top-nav): official guide on how to use Consul service to discover services and secure network traffic.
* [Deploy Consul Servers and Clients](core-concepts.md): Learn how to deploy consul servers and clients using this repo.

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
If you want to deploy this repo in production, check out the following resources:


[Consul Setup Guide](https://learn.hashicorp.com/consul/datacenter-deploy/deployment-guide)
  

## Support
If you need help with this repo or anything else related to infrastructure or DevOps, Gruntwork offers [Commercial Support](https://gruntwork.io/support/) via Slack, email, and phone/video. If you're already a Gruntwork customer, hop on Slack and ask away! If not, [subscribe now](https://www.gruntwork.io/pricing/). If you're not sure, feel free to email us at [support@gruntwork.io](mailto:support@gruntwork.io).


## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/hashicorp/terraform-aws-consul/tree/master/CONTRIBUTING.md) for instructions.


## License

Please see [LICENSE](LICENSE) for details on how the code in this repo is licensed.

Copyright &copy; 2019 Gruntwork, Inc.