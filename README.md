# Packer Template for Building Windows AMIs with SSH and Ansible over SSM

 - Boot straps EC2 with SSH then runs Packer and Ansible over an SSH tunnel through SSM.
 - Includes terraform for creating SSM instance profile and egress only SG.
