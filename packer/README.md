# Overview
![Create Packer Image](https://github.com/ralacher/azure-demos/workflows/Create%20Packer%20Image/badge.svg)<br/>
This demo uses Packer to create an Azure managed image and publish it to an Azure Shared Image Gallery using Packer and InSpec.

Packer uses a RedHat Enterprise Linux 7.3 image as its base and installs `httpd`, `git`, and `ansible`. It then runs InSpec to perform a simple test and outputs the test results in JUnit format.

The `images` directory contains sub-directories for each image, ARM templates to create the required infrastructure, InSpec configuration files, and Ansible playbooks (if applicable).

[Documentation](https://github.com/ralacher/azure-demos/wiki/Packer)
