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
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "enable_snapshot_agent" {
  description = "(Consul Enterprise only) If true, add policy rules to allow for snapshots to be sent to the specified s3 bucket"
  type        = bool
  default     = false
}

variable "snapshot_agent_bucket" {
  description = "(Consul Enterprise only) The s3 bucket name the snapshot agent writes to.  Required if enable_snapshot_agent is true."
  type        = string
  default     = null
}

variable "snapshot_agent_bucket_path" {
  description = "(Consul Enterprise only) The path within the s3 bucket that the snapshot agent writes to.  Defaults to consul-snapshot."
  type        = string
  default     = "consul-snapshot"
}
