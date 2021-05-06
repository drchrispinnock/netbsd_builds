#!/bin/sh

# Setup a Gentoo flavoured AWS instance
#
# Run as ec2-user
#
# At least 20G of disc is recommended
#

echo "===> Upgrading OS..." >&2
sleep 1
sudo emerge --sync
sudo emerge --oneshot sys-apps/portage
sudo emerge --update --deep --with-bdeps=y @world

# The instance I used had gcc, g++, zlib included.

sh ./setup_netbsd.sh curl
