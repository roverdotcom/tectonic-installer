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

data "ignition_systemd_unit" "kube2iam_iptables" {
  name    = "kube2iam-iptables.service"
  enabled = true

  content = <<EOF
[Unit]
Description=To prevent containers from directly accessing the ec2 metadata API and gaining unwanted access to AWS resources, the traffic to 169.254.169.254 must be proxied for docker containers.
After=network.target

[Service]
Type=oneshot
RemainAfterExit=true

User=root
Group=root
ExecStart=/usr/bin/bash -c " \
        /usr/sbin/iptables \
        --append PREROUTING \
        --protocol tcp \
        --destination 169.254.169.254 \
        --dport 80 \
        --in-interface cni0 \
        --jump DNAT \
        --table nat \
        --to-destination $(/bin/curl 169.254.169.254/latest/meta-data/local-ipv4):8181"

[Install]
WantedBy=multi-user.target
EOF
}

output "kube2iam_iptables_id" {
  value = "${data.ignition_systemd_unit.kube2iam_iptables.id}"
}
