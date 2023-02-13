provider "scaleway" {
  zone   = "fr-par-1"
  region = "fr-par"
}

provider "aws" {
  region = "eu-central-1"
}

resource "scaleway_iam_ssh_key" "main" {
  name       = "main"
  public_key = var.ssh
}

resource "scaleway_k8s_cluster" "k8s" {
  name    = "k8s"
  type    = "multicloud"
  version = "1.24.3"
  cni     = "kilo"
}

locals {
  k8s_id = trimprefix(scaleway_k8s_cluster.k8s.id, "fr-par/")
}


resource "scaleway_k8s_pool" "scaleway" {
  depends_on = [
    scaleway_iam_ssh_key.main
  ]
  cluster_id = scaleway_k8s_cluster.k8s.id
  name       = "scaleway"
  node_type  = "DEV1-M"
  size       = 1
}

resource "scaleway_k8s_pool" "aws" {
  cluster_id = scaleway_k8s_cluster.k8s.id
  name       = "aws"
  node_type  = "external"
  size       = 0
  min_size   = 0
}

resource "null_resource" "kubeconfig" {
  depends_on = [scaleway_k8s_pool.scaleway] # at least one pool here
  triggers = {
    host                   = scaleway_k8s_cluster.k8s.kubeconfig[0].host
    token                  = scaleway_k8s_cluster.k8s.kubeconfig[0].token
    cluster_ca_certificate = scaleway_k8s_cluster.k8s.kubeconfig[0].cluster_ca_certificate
  }
}

resource "local_file" "foo" {
  content  = scaleway_k8s_cluster.k8s.kubeconfig[0].config_file
  filename = "${path.module}/kubeconfig"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh
}

resource "aws_security_group" "ssh" {
  name = "launch-wizard-1"
  egress {
    cidr_blocks = [
      "0.0.0.0/0",
    ]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }

  ingress {
    cidr_blocks = [
      "176.162.179.185/32",
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
}

resource "aws_instance" "external" {
  count         = 1
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t4g.small"
  key_name      = aws_key_pair.deployer.id
  security_groups = [
    aws_security_group.ssh.name
  ]
}

provider "kubernetes" {
  config_path = "./kubeconfig"

}

provider "helm" {
  kubernetes {
    config_path = "./kubeconfig"
  }
}

output "aws_instances" {
  value = aws_instance.external.*.public_ip
}

output "scaleway_instances" {
  value = scaleway_k8s_pool.scaleway.nodes.*.public_ip
}

output "aws_pool_id" {
  value = trimprefix(scaleway_k8s_pool.aws.id, "fr-par/")
}
