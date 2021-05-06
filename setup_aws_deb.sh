#!/bin/sh

# Setup a Debian/Ubuntu flavoured AWS instance
#
# Run as admin on Debian and ubuntu on Ubuntu
#
# At least 15G of disc is recommended
#


echo "===> Upgrading OS..." >&2
sleep 1
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y install cvs libncurses5 libncurses5-dev gcc g++ zlib1g-dev zlib1g libssl-dev libudev-dev tnftp

sh ./setup_netbsd.sh
