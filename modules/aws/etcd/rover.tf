data "ignition_directory" "dd_agent_confd_dir" {
  filesystem = "root"
  mode       = 0755
  uid        = 0
  gid        = 0
  path       = "/etc/dd-agent/conf.d/"
}

data "ignition_file" "dd_agent_confd_etcd" {
  path       = "/etc/dd-agent/conf.d/etcd.yaml"
  mode       = 0644
  uid        = 0
  gid        = 0
  filesystem = "root"

  content {
    content = <<EOF
init_config:
instances:
  - url: "https://localhost:2379"
    ssl_keyfile: /etc/ssl/etcd/client.key
    ssl_certfile: /etc/ssl/etcd/client.crt
    ssl_cert_validation: false
    ssl_ca_certs: /etc/ssl/etcd/ca.crt
EOF
  }
}

data "ignition_systemd_unit" "dd_agent" {
  name    = "dd-agent.service"
  enabled = true

  content = <<EOF
[Unit]
Description=Datadog Agent
Requires=docker.service
After=docker.service
[Service]
Restart=always
ExecStartPre=-/usr/bin/docker stop dd-agent
ExecStartPre=-/usr/bin/docker rm -f dd-agent
ExecStartPre=/usr/bin/docker pull datadog/docker-dd-agent
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill dd-agent
ExecStartPre=-/usr/bin/docker rm dd-agent
ExecStart=/bin/bash -c " \
  docker run --name dd-agent \
    -h %H \
    --network=\"host\" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /proc/:/host/proc:ro \
    -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
    -v /etc/ssl/etcd:/etc/ssl/etcd:ro \
    -v /etc/dd-agent/conf.d:/conf.d:ro \
    -e API_KEY=\"${var.datadog_api_key}\" \
    -e TAGS=\"tectonic-cluster:${var.cluster_name}\" \
    datadog/docker-dd-agent"
ExecStop=/usr/bin/docker stop dd-agent
[Install]
WantedBy=multi-user.target
EOF
}

variable "datadog_api_key" {
  default = ""
}
