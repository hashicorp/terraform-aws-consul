# Consul Security Group Rules Module

This folder contains a [Terraform](https://www.terraform.io/) module that defines the security group rules used by a 
[Consul](https://www.consul.io/) cluster to control the traffic that is allowed to go in and out of the cluster. 

Normally, you'd get these rules by default if you're using the [consul-cluster module](/examples/consul-cluster), but if 
you're running Consul on top of a different cluster (e.g. you're co-locating Consul with Nomad), then you can use this 
module to add the necessary security group rules that that cluster.




## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "security_group_rules" {
  source = "github.com/gruntwork-io/consul-aws-blueprint//modules/consul-security-group-rules?ref=v0.0.1"

  security_group_id = "${module.some_cluster.security_group_id}"
  
  # ... (other params omitted) ...
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of this module. The double slash (`//`) is intentional 
  and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `security_group_id`: Use this parameter to specify the ID of the security group to which the rules in this module
  should be added.
  
You can find the other parameters in [vars.tf](vars.tf).

Check out the [consul-cluster module](/modules/consul-cluster) for working sample code.