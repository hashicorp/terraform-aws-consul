##NOTE: About [/modules](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules) and [/examples](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples]

Requirements of HashiCorp's Terraform Registry require every repo to have a `main.tf` in its root dir. The Consul code requires multiple modules which cannot all be in the root dir [/](https://github.com/hashicorp/terraform-aws-consul/tree/master). To accomodate this, Consul's required modules are in the [/modules](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules) subdirectory. The [/examples](https://github.com/hashicorp/terraform-aws-consul/tree/master/examples] subdirectory is example code for how to use Consul.

More info: https://github.com/hashicorp/terraform-aws-consul/pull/79/files/079e75015a5d89e7ffc89997aa0904e9de4cdb97#r212763365
