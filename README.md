# Consul AWS Blueprint

This repo contains a Blueprint for how to deploy a [Consul](https://www.consul.io/) cluster on 
[AWS](https://aws.amazon.com/) using [Terraform](https://www.terraform.io/). Consul is a distributed, highly-available 
tool that you can use for service discovery and key/value storage. A Consul cluster typically includes a small number
of server nodes, which are responsible for being part of the [concensus 
quorum](https://www.consul.io/docs/internals/consensus.html), and a larger number of client nodes, which you typically 
run alongside your apps:

![Consul architecture](/_docs/architecture.png)



## How to use this Blueprint

Each Blueprint has the following folder structure:

* [modules](/modules): This folder contains the reusable code for this Blueprint, broken down into one or more modules.
* [examples](/examples): This folder contains examples of how to use the modules.
* [test](/test): Automated tests for the modules and examples.

To deploy Consul servers using this Blueprint:

1. Create a Consul AMI using a Packer template that references the [install-consul module](/modules/install-consul).
   Here is an [example Packer template](/examples/consul-ami#quick-start). 
1. Deploy that AMI across an Auto Scaling Group using the Terraform [consul-cluster module](/modules/consul-cluster) 
   and execute the [run-consul script](/modules/run-consul), with `--server` set to `true`, during boot on each 
   Instance in the Auto Scaling Group to form the Consul cluster. Here is [an example Terraform 
   configuration](/examples/consul-cluster#quick-start) to provision a Consul cluster.

To deploy Consul clients using this Blueprint:
 
1. Use the [install-consul module](/modules/install-consul) to install Consul alongside your application code.
1. Before booting your app, execute the [run-consul script](/modules/run-consul), with `--server` set to `false`.
1. Your app can now using the local Consul agent for service discovery and key/value storage. 
 
 


## What's a Blueprint?

A Blueprint is a canonical, reusable, best-practices definition for how to run a single piece of infrastructure, such 
as a database or server cluster. Each Blueprint is created using [Terraform](https://www.terraform.io/), and
includes automated tests, examples, and documentation. It is maintained both by the open source community and 
companies that provide commercial support. 

Instead of figuring out the details of how to run a piece of infrastructure from scratch, you can reuse 
existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself, 
you can leverage the work of the Blueprint community to pick up infrastructure improvements through
a version number bump.
 
 
 
## Who maintains this Blueprint?

This Blueprint is maintained by [Gruntwork](http://www.gruntwork.io/). If you need help or support, send an email to 
[blueprints@gruntwork.io](mailto:blueprints@gruntwork.io?Subject=Consul%20Blueprint). Gruntwork can help with:

* Blueprints for other types of infrastructure, such as VPCs, Docker clusters, databases, and continuous integration.
* Blueprints that meet compliance requirements, such as HIPAA.
* Consulting & Training on AWS, Terraform, and DevOps.

## Code included in this Blueprint:

* [install-consul](/modules/install-consul): This module installs Consul using a
  [Packer](https://www.packer.io/) template to create a Consul 
  [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html).

* [consul-cluster](/modules/consul-cluster): The module includes Terraform code to deploy a Consul AMI across an [Auto 
  Scaling Group](https://aws.amazon.com/autoscaling/). 
  
* [run-consul](/modules/run-consul): This module includes the scripts to configure and run Consul. It is used
  by the above Packer module at build-time to set configurations, and by the Terraform module at runtime 
  with [User Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts)
  to create the cluster.



## How do I contribute to this Blueprint?

Contributions are very welcome! Check out the [Contribution Guidelines](/CONTRIBUTING.md) for instructions.



## How is this Blueprint versioned?

This Blueprint follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release, 
along with the changelog, in the [Releases Page](../../releases). 

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a 
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR, 
MINOR, and PATCH versions on each release to indicate any incompatibilities. 



## License

This code is released under the Apache 2.0 License. Please see [LICENSE](/LICENSE) and [NOTICE](/NOTICE) for more 
details.

