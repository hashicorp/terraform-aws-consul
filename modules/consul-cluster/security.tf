# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO CONTROL WHAT REQUESTS CAN GO IN AND OUT OF EACH EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "lc_security_group" {
  name_prefix = "${var.cluster_name}"
  description = "Security group for the ${var.cluster_name} launch configuration"
  vpc_id      = "${var.vpc_id}"

  # aws_launch_configuration.launch_configuration in this module sets create_before_destroy to true, which means
  # everything it depends on, including this resource, must set it as well, or you'll get cyclic dependency errors
  # when you try to do a terraform destroy.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_server_rpc_inbound" {
  type        = "ingress"
  from_port   = "${var.server_rpc_port}"
  to_port     = "${var.server_rpc_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_cli_rpc_inbound" {
  type        = "ingress"
  from_port   = "${var.cli_rpc_port}"
  to_port     = "${var.cli_rpc_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_serf_lan_tcp_inbound" {
  type        = "ingress"
  from_port   = "${var.serf_lan_port}"
  to_port     = "${var.serf_lan_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_serf_lan_udp_inbound" {
  type        = "ingress"
  from_port   = "${var.serf_lan_port}"
  to_port     = "${var.serf_lan_port}"
  protocol    = "udp"
  cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_serf_wan_tcp_inbound" {
  type        = "ingress"
  from_port   = "${var.serf_wan_port}"
  to_port     = "${var.serf_wan_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_serf_wan_udp_inbound" {
  type        = "ingress"
  from_port   = "${var.serf_wan_port}"
  to_port     = "${var.serf_wan_port}"
  protocol    = "udp"
  cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_http_api_inbound" {
  type        = "ingress"
  from_port   = "${var.http_api_port}"
  to_port     = "${var.http_api_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_dns_tcp_inbound" {
  type        = "ingress"
  from_port   = "${var.dns_port}"
  to_port     = "${var.dns_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_dns_udp_inbound" {
  type        = "ingress"
  from_port   = "${var.dns_port}"
  to_port     = "${var.dns_port}"
  protocol    = "udp"
  cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type        = "ingress"
  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_ssh_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}
