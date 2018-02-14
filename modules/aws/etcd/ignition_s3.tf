resource "aws_s3_bucket_object" "ignition_etcd_rover" {
  bucket  = "${var.s3_bucket}"
  key     = "ignition_etcd_rover.json"
  content = "${data.ignition_config.rover.rendered}"
  acl     = "private"

  server_side_encryption = "AES256"

  tags = "${merge(map(
      "Name", "${var.cluster_name}-ignition-rover",
      "KubernetesCluster", "${var.cluster_name}",
      "tectonicClusterID", "${var.cluster_id}"
    ), var.extra_tags)}"
}

data "ignition_file" "dd_agent_confd_etcd" {
  path       = "/home/core/etcd.yaml"
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

data "aws_ssm_parameter" "datadog_api_key" {
  name = "datadog_api_key"
}

data "ignition_systemd_unit" "dd_agent" {
  name   = "dd-agent.service"
  enable = true

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
    -v /home/core/etcd.yaml:/conf.d/etcd.yaml:ro \
    -e API_KEY=\"${data.aws_ssm_parameter.datadog_api_key.value}\" \
    -e TAGS=\"tectonic-cluster:${var.cluster_name}\" \
    datadog/docker-dd-agent"
ExecStop=/usr/bin/docker stop dd-agent
[Install]
WantedBy=multi-user.target
EOF
}

data "ignition_config" "rover" {
  systemd = [
    "${data.ignition_systemd_unit.dd_agent.id}",
  ]

  files = [
    "${data.ignition_file.dd_agent_confd_etcd.id}",
  ]
}
