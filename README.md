# Packer Template for Building Windows AMIs with SSH and Ansible over SSM

This repository contains a Packer template for building Windows AMIs. The process bootstraps an EC2 instance with SSH and then runs Packer and Ansible over an SSH tunnel through AWS Systems Manager (SSM). The repository also includes Terraform scripts for creating the necessary SSM instance profile and an egress-only security group.

## Features

- Bootstraps EC2 instances with SSH
- Runs Packer and Ansible over an SSH tunnel through SSM
- Includes Terraform scripts for:
    - Creating an SSM instance profile
    - Setting up an egress-only security group

## Prerequisites

Before you begin, ensure you have the following installed on your local machine:

- [Packer](https://www.packer.io/downloads)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [Terraform](https://www.terraform.io/downloads)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

## Security Benefits

### Using AWS Systems Manager (SSM)

1. **No Direct SSH Access**
   - By using SSM, there is no need to open SSH ports on the instance, reducing the attack surface.
   - SSH access is tunneled through SSM, which is controlled by IAM policies, offering better access control.

2. **Session Logging**
   - SSM Session Manager can log all commands and sessions to Amazon CloudWatch or Amazon S3, providing auditability and traceability for security and compliance purposes.

3. **IAM Role-Based Access**
   - Access through SSM is controlled via IAM roles and policies, enabling fine-grained access control based on least privilege principles.

4 **Enhanced Security**
- With SSM you can Build AMIs in a private subnet ensures that the instances do not have direct access to the internet, protecting them from external attacks during the build process.

5 **Isolation**
- Instances in a private subnet are isolated from the public internet, reducing the risk of exposure to potential threats.

## Getting Started

1. **Clone the Repository**

   ```sh
   git clone https://github.com/your-username/packer-windows-ami-ssm.git
   cd packer-windows-ami-ssm
   ```

2. **Configure AWS CLI**

   Ensure your AWS CLI is configured with the necessary permissions to create resources.

   ```sh
   aws configure
   ```

3. **Terraform Setup**

   Initialize Terraform and apply the configuration to create the SSM instance profile and security group.

   ```sh
   cd terraform
   terraform init
   terraform apply
   ```

4. **Build the AMI with Packer**

   Navigate to the Packer template directory and build the AMI.

   ```sh
   cd packer
   packer build windows-ami.json
   ```

## Packer Configuration

The Packer template `windows-ami.json` includes configurations to bootstrap an EC2 instance with SSH and run Ansible over an SSH tunnel through SSM.

## Ansible Playbooks

Ansible playbooks are stored in the `ansible` directory. These playbooks are executed by Packer to configure the Windows AMI.

## Links

- [Packer](https://www.packer.io/)
- [Ansible](https://www.ansible.com/)
- [AWS Systems Manager (SSM)](https://aws.amazon.com/systems-manager/)
- [Terraform](https://www.terraform.io/)

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any changes.
