data "ignition_config" "main" {
  files = [
    "${var.ign_installer_kubelet_env_id}",
    "${var.ign_installer_runtime_mappings_id}",
    "${var.ign_max_user_watches_id}",
    "${var.ign_s3_puller_id}",
    "${data.ignition_file.resolved_conf_dropin.id}",
  ]

  systemd = [
    "${var.ign_docker_dropin_id}",
    "${var.ign_k8s_node_bootstrap_service_id}",
    "${var.ign_kubelet_service_id}",
    "${var.ign_locksmithd_service_id}",
  ]
}

data "aws_region" "current" {
  current = true
}

data "ignition_file" "resolved_conf_dropin" {
  filesystem = "root"
  path       = "/etc/systemd/resolved.conf.d/10-resolved-conf.conf"
  mode       = 0644

  content {
    content = <<EOF
[Resolve]
Domains=${data.aws_region.current.name == "us-east-1" ? "ec2.internal" : "${data.aws_region.current.name}.compute.internal"}
EOF
  }
}
