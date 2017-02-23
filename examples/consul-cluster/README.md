# Consul Cluster Example

This folder shows an example of Terraform code that uses the [consul-cluster](/modules/consul-cluster) module to deploy 
a [Consul](https://www.consul.io/) cluster across an Auto Scaling Group in [AWS](https://aws.amazon.com/). 

![Consul architecture](/_docs/architecture.png)

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Consul installed, which you can do using the [consul-ami example](/examples/consul-ami)).  

For more info on how the Consul cluster works, check out the [consul-cluster](/modules/consul-cluster) documentation.



## Quick start

To deploy a Consul Cluster:

1. `git clone` this repo to your computer.
1. Build a Consul AMI. See the [consul-ami example](/examples/consul-ami) documentation for instructions. Make sure to
   note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including putting your AMI ID into the `ami_id` variable.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

Once the `apply` command finishes, open the [EC2 Console](https://console.aws.amazon.com/ec2/v2/home) in your browser
and you should see the EC2 Instances launching. After a minute or two, they should automatically find each other and
form a cluster. 

Click on one of the Instances in the console, copy its public IP address, and run the following:

```
> consul members -rpc-addr=<INSTANCE_IP_ADDR>:8400

Node                 Address             Status  Type    Build  Protocol  DC
i-02dbaa6ab6defffd5  172.31.0.127:8301   alive   server  0.7.5  2         us-east-1
i-0614bc1bb3d8c3a5e  172.31.41.172:8301  alive   server  0.7.5  2         us-east-1
i-072d920b2a927c48b  172.31.55.82:8301   alive   server  0.7.5  2         us-east-1
```

You can try inserting a value:

```
> consul kv put -http-addr=<INSTANCE_IP_ADDR>:8500 foo bar

Success! Data written to: foo
```

And reading that value back:
 
```
> consul kv get -http-addr=<INSTANCE_IP_ADDR>:8500 foo

bar
```

You can also open up the Consul UI in your browser at the URL `http://<INSTANCE_IP_ADDR>:8500/ui/`.