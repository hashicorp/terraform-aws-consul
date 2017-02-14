# Consul Install Scripts

This folder contains scripts for installing and configuring Consul:
 
1. `install-consul`: This script installs Consul, its dependencies, and the `run-consul` script.
1. `run-consul`: This script can be used when a system is first booting up to configure Consul so that it runs
   on startup and automatically finds other Consul nodes to form a cluster.

Note that these scripts are designed to be modular, so they can be combined with other scripts (e.g. you could 
install Consul and Vault on the same server), and cross-platform, so they should work on all major Linux distributions.



## Quick start

The best way to install these scripts on your server is to create a [Packer](https://www.packer.io/) template:

TODO: we need to figure out how to "package" (and write) these scripts. See the [Package Manager](#package-manager)
section for a discussion.



## The install-consul script

The `install-consul` script does the following:

1. [Install the Consul binary](#install-the-consul-binary)
1. [Create a user for Consul](#create-a-user-for-consul)
1. [Create an initial Consul configuration](#create-an-initial-consul-configuration)
1. [Install a process supervisor](#install-a-process-supervisor)
1. [Install the run-consul script](#install-the-run-consul-script)

### Install the Consul binary

Download the Consul zip file from the [downloads page](https://www.consul.io/downloads.html) (the version number is 
configurable), and extract the `consul` binary into `/usr/bin` (this directory is configurable, but should be part of
`PATH`).

### Create a user for Consul

Create an OS user named `consul` with execute permissions for the `consul` binary. Create the following folders, all
owned by user `consul`:

* `/opt/consul`: base directory for Consul data (configurable).
* `/opt/consul/data`: directory where the Consul agent can store state.
* `/opt/consul/config`: directory where the Consul agent looks up configuration.

### Create an initial Consul configuration

Copy over a basic config file into `/opt/consul/config/consul-base.json`. See 
[consul-config-default.json](consul-config-default.json) for the default config values. You can override this file with
your own config file when running the `install-consul` script. Refer to the Consul [configuration 
documentation](https://www.consul.io/docs/agent/options.html) for available configuration options and what each one
does.

Note that some configuration values are not known until runtime (e.g. `bind_addr`), so they show up in 
[consul-config-default.json](consul-config-default.json) with the placeholder value `__REPLACEME__`. The 
`run-consul` script is responsible for filling in these values while the server is booting. See 
the [run-consul script docs](#the-run-consul-script) for details on which variables it fills in. If you
specified a custom config file, you can use the same `__REPLACEME__` syntax to have those values filled in at runtime.

### Install a process supervisor
 
We want to run the Consul process on boot and to automatically restart the process if it crashes. To do that, we need
a process supervisor that works across a variety of Linux distributions. The most popular options are:

- systemd: available by default on Fedora/RHEL/Ubuntu 16.04.
- upstart: available by default on Ubuntu before 15.04.
- initd: available by default on Amazon Linux.
- supervisord: can be installed separately on most OS's.
 
TODO: pick a process supervisor 

### Install the run-consul script

Install the `run-consul` script into `/usr/bin` (this directory is configurable, but should be part of `PATH`).



## The run-consul script

The `run-consul` script is meant to be executed when the Consul server is first booting up. The most common way
to do this is to run it from [User Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts).
 
The `run-consul` script does the following:
 
1. [Fill in placeholders in the Consul configuration file](#fill-in-placeholders-in-the-consul-configuration-file)
1. [Start Consul using a process supervisor](#start-consul-using-a-process-supervisor)
 
### Fill in placeholders in the Consul configuration file

The `install-consul` script creates a Consul configuration file under `/opt/consul/config/consul-base.json`. This file
contains placeholders of the format `__REPLACEME__` that the `run-consul` script fills in with dynamic values.
To fill in a value, pass the argument `--set-config KEY=VALUE` to the `run-consul` script. For example:

```
run-consul --set-config datacenter=foo --set-config node=bar 
```

The following values are filled in by default:

* `advertise_addr`: Set to the EC2 Instance's private IP address, as fetched from 
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

* `bootstrap_expect`: This value should be passed into the script from the Terraform code. It should be set to the 
  number of EC2 Instances in the cluster (typically 3 or 5).
  
* `bind_addr`: Set to the EC2 Instance's private IP address, as fetched from 
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

* `datacenter`: This value should be passed into the script from the Terraform code. It should typically be set to the
  name of the current AWS region (e.g. `us-east-1`).
   
* `retry_join_ec2_tag_value`: This value should be passed into the script from the Terraform code. It should typically
  be set to the name of the Consul cluster (e.g. `consul-stage`).

* `node`: Set to the instance id, as fetched from 
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

### Start Consul using a process supervisor

TODO: this section depends on what process supervisor we pick


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

## Package Manager

We need to write and package these scripts in a way that satisfies the following requirements:

- **Packages**. There needs to be a way to fetch these scripts from a canonical location (e.g. GitHub repo, package 
  manager repository) at a specific version number (e.g. `v0.0.3` of `install-consul`), much like a package manager. 
  We don't want people copy/pasting these scripts into their local repos, or it'll make upgrades painful. 

- **Cross-platform**. The packaging system should work on all major Linux distributions.

- **Handles dependencies**. These scripts rely on certain dependencies being installed on the system, such as `curl`,
  `wget`, `jq`, `aws`, and so on. We need a way to automatically manage and install these dependencies that works
  across all major Linux distributions. 

- **Simple package manager installation**: We don't want a package manager that takes a dozen steps to install. 

- **Simple client usage**. These are simple scripts, so it shouldn't take a dozen steps to install one. Ideally, we can
  use a one-liner such as `apt install -y install-consul`, except it should work on all major Linux distributions.

- **Simple publish usage**. We need a fast and reliable way to publish new versions of packages. Ideally, we'd avoid
  having to publish each update to multiple package repos (apt, yum, etc), especially if that requires any sort of 
  manual approval (e.g. a PR for each new version). 

- **Testable in dev mode**. You must be able to do local, iterative development on the example code in the 
  [examples](/examples) folder. That means there is a way to "package" these scripts so that, in dev mode, they are
  downloaded from your local file system (rather than some package repo such as apt or yum).

- **Active community**: We want to use a Package manager with an active community. 

TODO: pick a package manager!

Here are the options we've looked at that work on all major Linux distributions are:

- [Nix](https://nixos.org/nix/)
    - Purely functional package manager, so dependency versioning, rollback, etc works very cleanly.
    - Has dependency-management built-in, though you are subject to what's available in the Nix repos.
    - Simple to install: `bash <(curl https://nixos.org/nix/install)`.
    - Simple client usage: `nix-env --install PACKAGE`.
    - Complicated publish usage. Nix has its own [expression 
      language](https://nixos.org/nix/manual/#sec-expression-syntax), which I found fairly confusing. The docs are
      so-so. Creating new packages and pushing new versions seems to require [a pull 
      request](https://nixos.org/wiki/Create_and_debug_nix_packages).
    - Not clear how to test in dev mode.  
    - Community seems fairly active.  

- [tpkg](http://tpkg.github.io/)
    - Package apps as super-powered tar files.
    - Has dependency-management built-in, both using native installers (e.g. apt) and tpkg itself.
    - Hard to install. Requires Ruby and Ruby Gems to be installed first, so every Packer template would have to 
      install Ruby (e.g. `sudo apt install ruby`), which many people won't want on their production servers, and then 
      install `tpkg`: `sudo gem install tpkg`. 
    - Simple client usage: `tpkg --install PACKAGE`.
    - Relatively simple publish usage: `tpkg --make PATH`. That produces a file you can upload to your own [package 
      server](http://tpkg.github.io/package_server.html), which can be any web server that hosts the file and a special
      metadata file. Might be able to use GitHub releases or S3 for this.
    - Easy to use in dev mode: the `tpkg --make PATH` command makes the package available for local install.   
    - Is it a dead project? The [GitHub repo](https://github.com/tpkg) has almost no followers. Only a couple commits 
      in the last few years.

- [Snap](https://snapcraft.io/)
    - A way to install "apps" on all major Linux distributions. It seems like it's designed for standalone apps and
      binaries rather than scripting. Packages, called "snaps", are completely isolated from each other and the host OS 
      (using cgroups?) and can define interfaces, slots, plugs, etc to communicate with each other (a bit like "type 
      safety").
    - Does not seem to have dependency management built-in. Or at least, I can't find it.
    - Simple client usage: `sudo snap install PACKAGE`.
    - Simple to install: `sudo apt install snapd`. 
    - Publishing is so-so. You have to sign up for an account in the [Ubuntu 
      Store](https://myapps.developer.ubuntu.com/), install a separate app (`sudo apt install snapcraft`), login
      (`snapcraft login`), configure channels (stable, beta, etc); after that, it's an easy `snapcraft push` command 
      for each new version.
    - Dev mode usage seems to work well with `snapcraft`.
    - Community seems fairly active, as this is a project maintained by Canonical.  

- `curl | bash`
    - Upload our scripts to Git, release them with version numbers, and pipe `curl` into `bash` to run them.
    - No dependency management is built-in.
    - Nothing to install! Well, perhaps `curl`, but that's as simple as it gets.
    - Simple client usage: `curl -Ls https://raw.githubusercontent.com/foo/bar/v0.0.3/consul-install | bash /dev/stdin`.
      Unfortunately, without any checksum or signature verification, this is a mild security risk if the GitHub repo 
      gets hijacked. Moreover, this only works for individual files. If the script has dependencies, those have to
      be downloaded separately.
    - Simple publish usage: just create a new GitHub release.
    - Easy to use in dev mode: just change the URL to a local file path.
    - No need for a community, as we're just using `curl`!   

- [Gruntwork Installer](https://github.com/gruntwork-io/gruntwork-installer)
    - A slightly more structured version of piping `curl` into `bash`. You specify a GitHub repo, a path, and a version 
      number and the installer checks out the repo at the specified version, and runs an `install.sh` script in the
      specified path.
    - Dependency management is self-serve. It's up to the `install.sh` script to figure out the details.
    - Simple install: `curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version v0.0.14`.
      Note, this is subject to the same security risks as piping `curl` into `bash`. Since there is just one installer
      and we don't update it often, we could publish it into apt, yum, etc repos to avoid this problem.
    - Simple client usage: `gruntwork-install --module-name 'PATH' --repo 'https://github.com/foo/bar' --tag v0.0.3`.
      Does not currently do checksum or signature verification, but that could be added.
    - Simple publish usage: just create a new GitHub release. Works with private GitHub repos too.
    - Easy to use in dev mode: specify a local file path.
    - Tiny community, but actively maintained by Gruntwork.

- [fpm](https://github.com/jordansissel/fpm)
    - A script that makes it easy to package your code as native packages (e.g. `.deb`, `.rpm`).
    - Has dependency management built-in, as you can specify dependencies for each package. 
    - No install process, as you use your standard OS package managers (i.e. `apt`, `yum`).
    - Simple client usage: `sudo apt install -y PACKAGE`.
    - Difficult publish usage: have to package and publish to all major Linux package repos.
    - Not clear how you use it in dev mode.
    - Big community, active project.

- Configuration management tools (e.g. [Ansible](https://www.ansible.com/), [Chef](https://www.chef.io/))
    - Tools built for managing server configuration.
    - Dependency management is built-in, as most of these tools have ways of leveraging the built-in package managers
      (e.g. [package command in Chef](https://docs.chef.io/resource_package.html) and [package command in 
      Ansible](http://docs.ansible.com/ansible/package_module.html)).
    - Simple install process. Packer can do it automatically for [Chef 
      Solo](https://www.packer.io/docs/provisioners/chef-solo.html) and you can do it manually for Ansible:
      `sudo apt install -y ansible`.
    - Moderately client usage. You first have to download the Chef Recipe or Ansible Playbook from the Blueprint
      repo (e.g. using a `shell-local` provisioner with `curl`) and then you can use the downloaded recipe or playbook 
      with the built-in Packer commands (e.g. [chef-solo 
      Provisioner](https://www.packer.io/docs/provisioners/chef-solo.html) and [ansible-local 
      Provisioner](https://www.packer.io/docs/provisioners/ansible-local.html)).
    - Easy publish usage: just create a new GitHub release.
    - Easy to use in dev mode: use local file paths for the recipes and playbooks.
    - All these cfg mgmt tools have massive communities.   