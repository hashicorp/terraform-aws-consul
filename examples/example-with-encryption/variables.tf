# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "ami_id" {
  description = "The ID of the AMI to run in the cluster. This should be an AMI built from the Packer template under examples/example-with-encryption/packer/consul-with-certs.json. To keep this example simple, we run the same AMI on both server and client nodes, but in real-world usage, your client nodes would also run your apps. If the default value is used, Terraform will look up the latest AMI build automatically."
  default     = ""
}

variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "What to name the Consul cluster and all of its associated resources"
  default     = "consul-example"
}

variable "num_servers" {
  description = "The number of Consul server nodes to deploy. We strongly recommend using 3 or 5."
  default     = 3
}

variable "num_clients" {
  description = "The number of Consul client nodes to deploy. You typically run the Consul client alongside your apps, so set this value to however many Instances make sense for your app code."
  default     = 3
}

variable "cluster_tag_key" {
  description = "The tag the EC2 Instances will look for to automatically discover each other and form a cluster."
  default     = "consul-servers"
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
  default     = ""
}

variable "vpc_id" {
  description = "The ID of the VPC in which the nodes will be deployed.  Uses default VPC if not supplied."
  default     = ""
}

variable "spot_price" {
  description = "The maximum hourly price to pay for EC2 Spot Instances."
  default     = ""
}

variable "enable_gossip_encryption" {
  description = "Encrypt gossip traffic between nodes. Must also specify encryption key."
  default = "true"
}

variable "enable_rpc_encryption" {
  description = "Encrypt RPC traffic between nodes. Must also specify TLS certificates and keys."
  default = "true"
}

variable "gossip_encryption_key" {
  description = "16 byte cryptographic key to encrypt gossip traffic between nodes. Must set 'enable_gossip_encryption' to true for this to take effect. WARNING: Setting the encryption key here means it will be stored in plain text. We're doing this here to keep the example simple, but in production you should inject it more securely, e.g. retrieving it from KMS."
  default = ""
}

variable "ca_path" {
  description = "Path to the directory of CA files used to verify outgoing connections."
  default = "/opt/consul/tls/ca"
}

variable "cert_file_path" {
  description = "Path to the certificate file used to verify incoming connections."
  default = "/opt/consul/tls/consul.crt.pem"
}

variable "key_file_path" {
  description = "Path to the certificate key used to verify incoming connections."
  default = "/opt/consul/tls/consul.key.pem"
}