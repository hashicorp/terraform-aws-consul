# Consul Install Scripts

This folder contains scripts for installing and configuring Consul:
 
1. `install-consul`: This script installs Consul, its dependencies, and the `run-consul` script.
1. `run-consul`: This script can be used when a system is first booting up to run Consul and configure it to 
   automatically find other Consul nodes to form a cluster.

You can use these scripts together to create a Consul [Amazon Machine Image 
(AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) that can be deployed across an Auto Scaling Group
using the [consul-cluster module](/modules/consul-cluster).

These scripts have been tested with: 

* Ubuntu 16.04
* Amazon Linux



## Quick start

To use these scripts to install Consul, use `git` to check out a specific version of this repo (see the 
[releases page](../../../../releases) for version numbers and the CHANGELOG) and run the `install-consul` script:

```
# TODO: update this to the final URL when this Blueprint is released
git clone --branch <VERSION> https://github.com/gruntwork-io/consul-aws-blueprint.git
./consul-aws-blueprint/modules/consul-install/install-consul
```

Once the `install-consul` script is finished, Consul will be installed, and you can run it using the `run-consul` 
script:

```
run-consul
```

We recommend creating an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
with Consul installed by running `install-consul` as part of a [Packer](https://www.packer.io/) template using a
[shell provisioner](https://www.packer.io/docs/provisioners/shell.html) (see the [consul-ami 
example](/examples/consul-ami) for a fully-working sample code). You can then deploy the AMI across an Auto
Scaling Group using the [consul-cluster module](/modules/consul-cluster) (see the [consul-cluster 
example](/examples/consul-cluster) for fully-working sample code).

You can find more documentation for each script below:

1. [The install-consul script](#the-install-consul-script)
1. [The run-consul script](#the-run-consul-script)




## The install-consul script

### Command line Arguments

The `install-consul` script accepts the following arguments, all optional:

* `version VERSION`: Install Consul version VERSION.  
* `path DIR`: Install Consul into folder DIR.

Example:

```
install-consul --version 0.7.5 --path /opt/consul
```

### How it works

The `install-consul` script does the following:

1. [Create a user and folders for Consul](#create-a-user-and-folders-for-consul)
1. [Install Consul binaries and scripts](#install-consul-binaries-and-scripts)
1. [Install supervisord](#install-supervisord)

#### Create a user and folders for Consul

Create an OS user named `consul`. Create the following folders, all owned by user `consul`:

* `/opt/consul`: base directory for Consul data (configurable via the `--path` argument).
* `/opt/consul/bin`: directory for Consul binaries.
* `/opt/consul/data`: directory where the Consul agent can store state.
* `/opt/consul/config`: directory where the Consul agent looks up configuration.

#### Install Consul binaries and scripts

Install the following:

* `consul`: Download the Consul zip file from the [downloads page](https://www.consul.io/downloads.html) (the version 
  number is configurable via the `--version` argument), and extract the `consul` binary into `/opt/consul/bin`.
* `run-consul`: Copy the `run-consul` script from this module into `/opt/consul/bin`. 

#### Install supervisord

Install [supervisord](http://supervisord.org/). We use it as a cross-platform supervisor to ensure Consul is started
whenever the system boots and restarted if the Consul process crashes.



## The run-consul script

### Command line arguments

The `run-consul` script accepts one or more arguments of the following format:

* `-ARG=VALUE`: When running Consul, set argument ARG to value VALUE. May be specified more than once. This
  is used to set configurations for Consul at runtime. Check out the [Consul Configuration 
  docs](https://www.consul.io/docs/agent/options.html) for a list of supported arguments.

Example:

```
run-consul -bootstrap-expect=3 -advertise-addr=11.22.33.44
```

#### Required arguments

The following arguments are required:
   
* `retry-join-ec2-tag-key KEY`: Look for EC2 Instances with a tag named KEY and the value specified by the  
  `retry-join-ec2-tag-value` argument and join them to form a Consul cluster. If you assign a custom tag to all the 
  instances in your Consul Auto Scaling Group, then each of them will be able to use that tag to automatically find 
  discover each other using the AWS APIs.

* `retry-join-ec2-tag-value VALUE`: Look for EC2 Instances with the tag name specified by the `retry-join-ec2-tag-key`
  argument and the value VALUE and join them to form a Consul cluster. If you assign a custom tag to all the 
  instances in your Consul Auto Scaling Group, then each of them will be able to use that tag to automatically find 
  discover each other using the AWS APIs.
  
* `bootstrap-expect CLUSTER_SIZE`: Wait for CLUSTER_SIZE nodes to join to form a cluster. You should set this to the 
  size of your Consul Auto Scaling Group.
  
#### Default arguments

The `run-consul` script sets the following arguments by default:

* `advertise-addr`: Set to the EC2 Instance's private IP address, as fetched from 
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

* `bind-addr`: Set to the EC2 Instance's private IP address, as fetched from 
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

* `config-dir`: Set to `CONSUL_HOME/config`, where `CONSUL_HOME` is the value of the `--path` argument passed to the 
  `install-consul` script (`/opt/consul` by default).

* `data-dir`: Set to `CONSUL_HOME/data`, where `CONSUL_HOME` is the value of the `--path` argument passed to the 
  `install-consul` script (`/opt/consul` by default).

* `datacenter`: Set to the current AWS region (e.g. `us-east-1`).

* `node`: Set to the instance id, as fetched from 
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

* `server`: Set to true.

* `ui`: Set to true.

To override a default value for an argument, pass that argument to the `run-consul` command. For example, to override 
the default `advertise-addr` value, you would run:

```
run-consul -advertise-addr=11.22.33.44
```
  
### How it works

The `run-consul` script is meant to be executed when the Consul server is first booting up. The most common way
to do this is to run it as a [User Data
script](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts).

When you execute the `run-consul` script, it configures [supervisord](http://supervisord.org/) to run a start script
for Consul. Here's what that start script does:
  
1. [Check if a Consul cluster already exists](#check-if-a-consul-cluster-already-exists)  
1. [Bootstrap Consul if a cluster doesn't already exist](#bootstrap-consul-if-a_cluster-doesnt-already-exist) 
1. [Do a rolling update if a cluster already exists](#do-a-rolling-update-if-a-cluster-already-exists)
 
#### Check if a Consul cluster already exists 
 
1. Use the AWS CLI to look up other EC2 Instances with the tags identified by the `retry-join-ec2-tag-key` and
   `retry-join-ec2-tag-value` arguments.
1. Call the `/v1/status/leader` endpoint on each node.
1. If a 200 OK comes back with a JSON body identifying an elected leader, the Consul cluster must already exist.
1. If a 200 OK comes back without a leader, sleep, and try again. If after 5 minutes, there is still no leader, exit
   with an error.
1. If a non-200 OK comes back or there is no response, assume the Consul cluster does not exist.   
 
#### Bootstrap Consul if a cluster doesn't already exist
 
If there isn't already a Consul cluster, we simply execute a command of the following form to bootstrap one:

```
consul agent -server -bootstrap-expect=<CLUSTER_SIZE> -retry-join-ec2-tag-key=<KEY> -retry-join-ec2-tag-value=<VALUE> [OTHER_ARGS...]
``` 

#### Do a rolling update if a cluster already exists

If the Consul cluster already exists, then we want to deploy an update. Adding or removing too many nodes in a short 
time period can lead to (rare) cases where Consul loses its quorum, so we need to roll out the update carefully, adding
one new node and removing one old node at a time.
 
To do that, all the new nodes will run the following code as they boot:
 
```
consul lock -http-addr=<NODE_IP>:8500 rolling-update <JOIN_SCRIPT>
``` 

Where `NODE_IP` is the IP address of one of the existing nodes in the Consul Cluster and `JOIN_SCRIPT` is a script that
adds the current node to the cluster and removes an old node (the script is described below). We use a 
[Consul lock](https://www.consul.io/docs/commands/lock.html) to ensure that only one node is joining/leaving at a time;
all the other servers that are booting will have to wait their turn.
   
The `JOIN_SCRIPT` works as follows:   
   
1. Have the current node join the cluster. This is done using a command of the following form: 

    ```
    consul agent -server -retry-join-ec2-tag-key=<KEY> -retry-join-ec2-tag-value=<VALUE> [OTHER_ARGS...]
    ```
    
1. Once the node has successfully joined the cluster, it will deregister one of the older nodes: 

    ```
    curl -X PUT <OLD_NODE_IP>:8500/v1/agent/leave
    ```

    Where OLD_NODE_IP is the IP of an older node. Note: we have to ensure `NODE_IP` != `OLD_NODE_IP`, or the 
    `consul lock` command will exit with an error. 



## How do you handle encryption?

Consul can encrypt all of its network traffic (see the [encryption docs for 
details](https://www.consul.io/docs/agent/encryption.html)), but by default, encryption is not enabled in this 
Blueprint. To enable encryption, you need to do the following:

1. [Gossip encryption: provide an encryption key](#gossip-encryption-provide-an-encryption-key)
1. [RPC encryption: provide TLS certificates](#rpc-encryption-provide-tls-certificates)

### Gossip encryption: provide an encryption key

To enable Gossip encryption, you need to provide a 16-byte, Base64-encoded encryption key (you can generate it using
the [consul keygen command](https://www.consul.io/docs/commands/keygen.html)) in the Consul configuration:

```json
{
  "encrypt": "cg8StVXbQJ0gPvMd9o7yrg=="
}
```

One option is to provide a custom configuration file that includes this encryption key when calling the 
`install-consul` script from the [consul-install](/modules/consul-install) module. If you do this as part of a Packer
template, the encryption key will be baked into the AMI you deploy, and every Consul server will be able to use it. 

If the encryption key cannot be baked into the AMI (e.g. because the key is only available at runtime), you can set
the configuration to the `__REPLACEME__` placeholder value:

```json
{
  "encrypt": "__REPLACEME__"
}
```

When the server is booting, you can pass the encryption key into the `run-consul` script and it will put the key into
Consul's config file just before starting Consul:

```
run-consul --set-config encrypt=cg8StVXbQJ0gPvMd9o7yrg== 
```

### RPC encryption: provide TLS certificates

To enable RPC encryption, you need to provide the paths CA and signing keys ([here is a tutorial on generating these
keys](http://russellsimpkins.blogspot.com/2015/10/consul-adding-tls-using-self-signed.html)) in the Consul 
configuration:

```json
{
  "ca_file": "/opt/consul/tls/certs/ca-bundle.crt",
  "cert_file": "/opt/consul/tls/certs/my.crt",
  "key_file": "/opt/consul/tls/private/my.key"
}
```

You will also want to set the [verify_incoming](https://www.consul.io/docs/agent/options.html#verify_incoming) and
[verify_outgoing](https://www.consul.io/docs/agent/options.html#verify_outgoing) settings to verify TLS certs on 
incoming and outgoing connections, respectively:

```json
{
  "ca_file": "/opt/consul/tls/certs/ca-bundle.crt",
  "cert_file": "/opt/consul/tls/certs/my.crt",
  "key_file": "/opt/consul/tls/private/my.key",
  "verify_incoming": true,
  "verify_outgoing": true
}
```

One option is to provide a custom configuration file that includes these settings when calling the 
`install-consul` script from the [consul-install](/modules/consul-install) module. If you do this as part of your 
Packer template, and that template copies in the CA and signing keys, then everything you need for TLS will be baked 
into into the AMI you deploy, and every Consul server will be able to use it. 

If the CA and signing keys cannot be baked into the AMI (e.g. because they are only available at runtime), you can set
these configs to the `__REPLACEME__` placeholder value:

```json
{
  "ca_file": "__REPLACEME__",
  "cert_file": "__REPLACEME__",
  "key_file": "__REPLACEME__",
  "verify_incoming": true,
  "verify_outgoing": true
}
```

When the server is booting, you can pass the encryption key into the `run-consul` script and it will put the key into
Consul's config file just before starting Consul:

```
run-consul \
  --set-config ca_file=/opt/consul/tls/certs/ca-bundle.crt \ 
  --set-config cert_file=/opt/consul/tls/certs/my.crt \ 
  --set-config key_file=/opt/consul/tls/private/my.key  
```


