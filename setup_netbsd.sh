#!/bin/sh

# Use this direct for FreeBSD

cdn='http://nycdn.netbsd.org/pub/NetBSD-daily/HEAD/latest/source/sets/'
sourcefiles="src.tgz syssrc.tgz sharesrc.tgz gnusrc.tgz xsrc.tgz"

if [ "$1" = "curl" ]; then
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
	tar zxf sources/$i
done

mv usr netbsd-current

