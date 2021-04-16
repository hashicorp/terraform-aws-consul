# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "iam_role_id" {
  description = "The ID of the IAM Role to which these IAM policies should be attached"
  type        = string
}

variable "enabled" {
  description = "Give the option to disable this module if required"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# You may provide a value for each of these parameters; in some cases they may be required if certain other options are turned on.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the cluster that is being created. This is only required if you set 'acl_store_type' to 'ssm', so that the instances can write to / read from SSM parameters under the cluster name root path."
  type        = string
  default  =  ""
}

variable "acl_store_type" {
  description = "The type of cloud store where the cluster will write / read ACL tokens. If left at the default then no related policies will be created."
  type        = string
  default     = ""
  validation {
    condition     = contains(["ssm",""],var.acl_store_type)
    error_message = "You must specify a supported store type for ACL tokens. Currently the only allowed value is 'ssm'."
  } 
}