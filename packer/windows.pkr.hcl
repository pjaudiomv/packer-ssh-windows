packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3"
    }
    windows-update = {
      version = "~> 0.16"
      source  = "github.com/rgl/windows-update"
    }
    ansible = {
      version = "~> 1.1.1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "ami_name_prefix" {
  type    = string
  default = "windows-base-2022"
}

variable "image_name" {
  type    = string
  default = "Windows Server 2022 image with ssh"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "aws-windows-ssh" {
  ami_name                 = "${var.ami_name_prefix}-${local.timestamp}"
  ami_description          = "${var.image_name}"
  ami_virtualization_type  = "hvm"
  spot_price               = "auto"
  spot_instance_types      = ["c6i.large", "c5a.large", "m7i.large", "m6a.large", "m5a.large", "m5.large"]
  communicator             = "ssh"
  ssh_interface            = "session_manager"
  ssh_timeout              = "10m"
  ssh_username             = "Administrator"
  ssh_file_transfer_method = "sftp"
  iam_instance_profile     = "DefaultSSMProfile"
  user_data_file           = "files/SetupSsh.ps1"

  fast_launch {
    enable_fast_launch = true
  }

  snapshot_tags = {
    Name      = "${var.image_name}"
    BuildTime = "${local.timestamp}"
  }

  tags = {
    Name      = "${var.image_name}"
    BuildTime = "${local.timestamp}"
  }

  security_group_filter {
    filters = {
      "tag:Name" : "packer-ssm"
    }
  }

  subnet_filter {
    filters = {
      "tag:Name" : "*-private-*"
    }
    most_free = true
    random    = false
  }

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }
}

build {
  sources = ["source.amazon-ebs.aws-windows-ssh"]

  provisioner "shell-local" {
    inline = [
      "attempt=0",
      "max_attempts=5",
      "sleep_interval=30",
      "until aws ssm send-command --document-name \"AWSEC2-ConfigureSTIG\" --document-version \"35\" --targets '[{\"Key\":\"InstanceIds\",\"Values\":[\"${build.ID}\"]}]' --parameters '{\"Level\":[\"Low\"]}' --timeout-seconds 600 --max-concurrency \"50\" --max-errors \"0\" --output-s3-bucket-name \"packer-windows-logs-114589198289\" --cloud-watch-output-config '{\"CloudWatchOutputEnabled\":true}' || [ $attempt -ge $max_attempts ]; do",
      "  attempt=$((attempt+1))",
      "  echo \"Retrying in $sleep_interval seconds...\"",
      "  sleep $sleep_interval",
      "done"
    ]
  }

  provisioner "ansible" {
    use_proxy     = false
    playbook_file = "${path.root}/ansible/playbook.yaml"
    user          = "Administrator"
    extra_arguments = [
      "--extra-vars",
      "ansible_shell_type=powershell",
      "--extra-vars",
      "ansible_shell_executable=None"
    ]
    inventory_file_template = "{{ .HostAlias }} ansible_host={{ .ID }} ansible_user={{ .User }} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand=\"sh -c \\\"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p\\\"\"'\n"
  }

  provisioner "windows-update" {}

  provisioner "powershell" {
    script = "files/InstallChoco.ps1"
  }

  provisioner "windows-restart" {
    max_retries = 3
  }

  provisioner "powershell" {
    inline = ["choco install winscp googlechrome -y"]
  }

  provisioner "powershell" {
    script = "files/PrepareImage.ps1"
  }
}
