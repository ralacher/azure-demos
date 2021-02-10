# Overview
This directory contains a Packer template to build a Windows Server 2019 image. The built image will be deployed to the specified Shared Image Gallery (SIG).

# Variables
Variables can be populated in two ways:
1. Update the variables section of `windows.json` to include environment variables using `{{ env ``VAR_NAME``}}` function
2. Update `variables.json` with the appropriate values and execute `packer build -var-file=variables.json`