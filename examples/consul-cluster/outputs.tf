output "num_servers" {
  value = "${var.num_servers}"
}

output "asg_name_servers" {
  value = "${module.consul_servers.asg_name}"
}

output "launch_config_name_servers" {
  value = "${module.consul_servers.launch_config_name}"
}

output "iam_role_arn_servers" {
  value = "${module.consul_servers.iam_role_arn}"
}

output "iam_role_id_servers" {
  value = "${module.consul_servers.iam_role_id}"
}

output "security_group_id_servers" {
  value = "${module.consul_servers.security_group_id}"
}

output "num_clients" {
  value = "${var.num_clients}"
}

output "asg_name_clients" {
  value = "${module.consul_clients.asg_name}"
}

output "launch_config_name_clients" {
  value = "${module.consul_clients.launch_config_name}"
}

output "iam_role_arn_clients" {
  value = "${module.consul_clients.iam_role_arn}"
}

output "iam_role_id_clients" {
  value = "${module.consul_clients.iam_role_id}"
}

output "security_group_id_clients" {
  value = "${module.consul_clients.security_group_id}"
}
