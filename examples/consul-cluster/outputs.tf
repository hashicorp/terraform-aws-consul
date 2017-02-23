output "asg_name" {
  value = "${module.consul.asg_name}"
}

output "cluster_size" {
  value = "${module.consul.cluster_size}"
}

output "launch_config_name" {
  value = "${module.consul.launch_config_name}"
}

output "iam_role_arn" {
  value = "${module.consul.iam_role_arn}"
}

output "iam_role_id" {
  value = "${module.consul.iam_role_id}"
}

output "security_group_id" {
  value = "${module.consul.security_group_id}"
}
