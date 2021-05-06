#!/bin/sh

# Setup a RPM flavoured AWS instance
#
# Run as ec2-user on AWS Linux or Redhat
#
# At least 15G of disc is recommended
#

echo "===> Upgrading OS..." >&2
sleep 1
sudo yum -y check-update
sudo yum -y upgrade
sudo yum -y install gcc gcc-c++ zlib zlib-devel curl

sh ./setup_netbsd.sh curl
