# How to Publish AMIs in a New Account

To make using this Blueprint as easy as possible, we want to automatically build and publish AMIs based on the 
[/examples/consul-ami/consul.json](/examples/consul-ami/consul.json) Packer template upon every release of this repo. 
This way, users can simply git clone this repo and `terraform apply` the [/examples/consul-cluster](/examples/consul-cluster)
without first having to build their own AMI. Note that the auto-built AMIs are meant mostly for first-time users to 
easily try out a Blueprint. In a production setting, many users will want to validate the contents of their AMI by
manually building it in their own account.

Unfortunately, auto-building AMIs creates a chicken-and-egg problem. How can we run code that automatically finds the
latest AMI until that AMI actually exists? But to build those AMIs, we have to run a build in CircleCI, which also runs
automated tests, which will fail when they cannot find the desired AMI. 

Our solution is that, for the `publish-amis` git branch only, on every commit, we will build and publish AMIs but we will
not run tests. For all other branches, AMIs will only be built upon a new git tag (GitHub release), and tests will be
run on every commit as usual. These settings are configured in the [circle.yml](/circle.yml) file.