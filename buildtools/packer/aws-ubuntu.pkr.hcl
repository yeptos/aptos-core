packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type = string
}

variable "ami_prefix" {
  type = string
}


data "amazon-ami" "runs-on-ami-x64" {
  filters = {
    name                = "runs-on-v2.2-ubuntu22-full-x64-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  # The Runs-On AMI is in the following account
  # ref: https://runs-on.com/guides/building-custom-ami-with-packer/
  owners      = ["135269210855"]
  region      = "${var.region}"
}

source "amazon-ebs" "build-ebs" {
  ami_name       = "${var.ami_prefix}-runs-on-${formatdate("YYYY-MM-DD-hhmmss", timestamp())}"
  instance_type  = "c7a.4xlarge"
  region         = "${var.region}"
  source_ami     = "${data.amazon-ami.runs-on-ami-x64.id}"
  ssh_username   = "ubuntu"
  user_data_file = "./user_data.sh"
}

build {
  name = "setup-ubuntu-22.04"
  sources = [
    "source.amazon-ebs.build-ebs"
  ]

  provisioner "file" {
    source      = "../../rust-toolchain.toml"
    destination = "/tmp/rust-toolchain.toml"
  }

  provisioner "file" {
    source      = "../../scripts"
    destination = "/tmp/scripts"
  }

  provisioner "shell" {
    inline = [
      "whoami",
      "chmod +x /tmp/scripts/dev_setup.sh",
      "sudo -u runner /tmp/scripts/dev_setup.sh -b -r -y -P -J -t -k",

      // Install GCloud SDK and kubectl
      "sudo apt-get install apt-transport-https ca-certificates gnupg -y",
      "echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list",
      "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -",
      "sudo apt-get update && sudo apt-get install google-cloud-sdk kubectl google-cloud-sdk-gke-gcloud-auth-plugin -y",
      // Verify installations
      "gcloud --version",
      "kubectl version --client",
      "gke-gcloud-auth-plugin --version"
    ]
  }
}
