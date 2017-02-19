variable "cluster_name" {
  description = "The name of the Consul cluster (e.g. consul-stage). This variable is used to namespace all resources created by this module."
}

variable "ami_id" {
  description = "The ID of the AMI to run in this cluster. Should be an AMI that had Consul installed and configured by the consul-install module."
}

variable "instance_type" {
  description = "The type of EC2 Instances to run for each node in the cluster (e.g. t2.micro)."
}

variable "subnet_ids" {
  description = "The subnet IDs into which the EC2 Instances should be deployed. We recommend one subnet ID per node in the cluster_size variable."
  type = "list"
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
}

variable "cluster_size" {
  description = "The number of nodes to have in the Consul cluster. We strongly recommended that you use either 3 or 5."
  default = 3
}

variable "user_data" {
  description = "A User Data script to execute while the server is booting. You should pass in a bash script that executes the run-consul script, which should have been installed in the Consul AMI by the consul-install module."
}

variable "custom_tags" {
  description = "Custom tags to add to the EC2 Instances in the ASG"
  type = "map"
  default = {}
}

variable "associate_public_ip_address" {
  description = "If set to true, associate a public IP address with each EC2 Instance in the cluster."
  default = false
}

variable "tenancy" {
  description = "The tenancy of the instance. Must be one of: default or dedicated."
  default = "default"
}

variable "root_volume_type" {
  description = "The type of volume. Must be one of: standard, gp2, or io1."
  default = "standard"
}

variable "root_volume_size" {
  description = "The size, in GB, of the root EBS volume."
  default = 50
}