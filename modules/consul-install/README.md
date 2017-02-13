# Consul Install Scripts

This folder contains two scripts for installing and configuring Consul:
 
1. `install-consul`: This script installs Consul, its dependencies, and the `configure-consul` script.
1. `configure-consul`: This script can be used when a system is first booting up to configure Consul so that it runs
   on startup and automatically finds other Consul nodes to form a cluster.

## Quick start (TODO)

The best way to install these scripts on your server is to create a [Packer](https://www.packer.io/) template:

TODO: we need to figure out how to "package" (and write) these scripts. See the [Package Manager](#package-manager)
section for a discussion.

## The install-consul script

The `install-consul` script does the following:

1. Install the Consul binary
1. Create a user for Consul
1. Create an initial Consul configuration
1. Install a process supervisor (TODO)
1. Install the configure-consul script

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

Copy over a basic config file into `/opt/consul/config/consul-base.json`. This contains the basic 
[configuration settings](https://www.consul.io/docs/agent/options.html) for Consul:

```json
{
  "advertise_addr": "__REPLACEME__",
  "bootstrap_expect": "__REPLACEME__",
  "bind_addr": "__REPLACEME__",
  "datacenter": "__REPLACEME__",
  "data_dir": "/opt/consul/data",
  "node": "__REPLACEME__",
  "retry_join_ec2_tag_value": "__REPLACEME__",
  "retry_join_ec2_tag_key": "consul-cluster",
  "retry_interval": "30s",
  "retry_max": 20,
  "server": true,
  "ui": true
}
```

Note, however, that a few configuration values are not known until runtime, so they show up in the configuration with 
the placeholder value `__REPLACEME__`. The `configure-consul` script is responsible for filling in these values while 
the server is booting. See the [configure-consul script docs](#the-configure-consul-script) for details on which 
variables it fills in.

Note that `install-consul` has a default `consul-base.json` that it uses, but you can override this with your own file
if you need custom configurations. You can use the same `__REPLACEME__` convention in your custom configuration file to 
indicate values that should be replaced by the `configure-consul` script during boot.

### Install a process supervisor (TODO)
 
We want to run the Consul process on boot and to automatically restart the process if it crashes. To do that, we need
a process supervisor that works across a variety of Linux distributions. The most popular options are:

- systemd: available by default on Fedora/RHEL.
- upstart: available by default on Ubuntu.
- supervisord: can be installed separately on most OS's.
 
TODO: pick a process supervisor 

### Install the configure-consul script

Install the `configure-consul` script into `/usr/bin` (this directory is configurable, but should be part of `PATH`).

## The configure-consul script

The `configure-consul` script is meant to be executed when the Consul server is first booting up. The most common way
to do this is to run it from [User Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts).
 
The `configure-consul` script does the following:
 
1. Fill in placeholders in the Consul configuration file
1. Start Consul using a process supervisor
 
### Fill in placeholders in the Consul configuration file

The `install-consul` script creates a Consul configuration file under `/opt/consul/config/consul-base.json`. This file
contains placeholders of the format `__REPLACEME__` that the `configure-consul` script fills in with dynamic values.
The following values are filled in:

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

Some of the options we've looked at that work on all major Linux distributions are:

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