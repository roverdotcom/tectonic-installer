variable "resolved_domains" {
  default = []
}

output "resolved_conf_id" {
  value = "${data.ignition_file.resolved_conf.id}"
}

data "ignition_file" "resolved_conf" {
  filesystem = "root"
  path       = "/etc/systemd/resolved.conf.d/10-resolved-conf.conf"
  mode       = 0644

  content {
    content = <<EOF
[Resolve]
Domains=${join(" ", var.resolved_domains)}
EOF
  }
}
