#!/bin/sh

# Setup a SuSe AWS instance for NetBSD builds
#
# Run as ec2-user on SuSe
#
# At least 15G of disc is recommended
#

echo "===> Upgrading OS..." >&2
sleep 1
sudo zypper update -y
sudo zypper install -y gcc gcc-c++ zlib zlib-devel curl

sh ./setup_netbsd.sh curl
