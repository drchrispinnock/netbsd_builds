#!/bin/sh

# Use this direct for FreeBSD or OpenBSD
# Linux will need additional packages

cdn='http://nycdn.netbsd.org/pub/NetBSD-daily/HEAD/latest/source/sets/'
sourcefiles="src.tgz syssrc.tgz sharesrc.tgz gnusrc.tgz xsrc.tgz"

which curl > /dev/null 2>&1
if [ "$?" = "0" ]; then
	curl=1
fi

mkdir -p sources
cd sources
echo "===> Fetching sources..." >&2
sleep 1

for i in $sourcefiles; do
	if [ "$curl" = "1" ]; then
		curl --output $i $cdn/$i
	else
		ftp -a $cdn/$i
	fi
done
cd ..
echo "===> Extracting sources..." >&2
sleep 1

for i in $sourcefiles; do
	echo "$i" >&2
	tar zxf sources/$i
	[ "$?" != "0" ] && echo "Error extracting $i" >&2 && exit 1
done

