
*Build Scripts*

Some quick and dirty scripts to wrap around the build.sh infra
and build releases.

e.g.

1. sh ~/buildwrapper.sh -j 8 -Q -x -A

Build all NetBSD architectures using 8 threads, minimal logging to the
console and attempting to build X.

2. setup_aws_*

Setup scripts for AWS instances to make them ready for building.

deb - Ubuntu and Debian Linux
rpm - Amazon and RedHat Linux
sus - SUSE Linux

3. setup_netbsd.sh

Called by the Linux scripts. For Open and FreeBSD you can use this
directly to setup a build environment

