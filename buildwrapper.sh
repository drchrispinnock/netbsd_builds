#!/bin/sh
#
# Build several platforms of NetBSD in a continous loop

# Platforms - loads of defaults ##########################################
#

# My preferences
#
mypref="amd64 sparc64 evbppc evbmips64-eb macppc riscv"
targets="$mypref" # Default
uploadurl="www.netbsd.org:public_html"
uploadr=1

# Tier 1 platforms (subset)
#
supported="amd64 i386 sparc64 evbppc hpcarm evbarm64-el evbarm64-eb evbmips64-eb evbmips64-el evbmips-eb evbmips-el"

# All EVBArm combinations
#
#evbarmv4-el evbarmv4-eb evbarmv5-el evbarmv5hf-el evbarmv5-eb evbarmv5hf-eb evbarmv6-el evbarmv6hf-el evbarmv6-eb evbarmv6hf-eb evbarmv7-el evbarmv7-eb evbarmv7hf-el evbarmv7hf-eb evbarm64-el evbarm64-eb

# Tier 2/Organic platforms
#
organic="acorn32 algor alpha amiga amigappc arc atari bebox cats cesfic	cobalt	dreamcast epoc32 emips evbsh3-eb evbsh3-el ews4800mips hp300 hppa hpcmips hpcsh ibmnws iyonix landisk luna68k mac68k macppc mipsco mmeye mvme68k mvmeppc netwinder news68k newsmips next68k ofppc pmax prep rs6000 sandpoint sbmips-eb sbmips-el sbmips64-eb sbmips64-el sgimips shark sparc sun2 sun3 vax x68k zaurus"
other="ia64 riscv"

# All targets
alltargets="$supported $organic $other"

# Defaults
#
# Number of CPUs - there must be a better way - shirley shome mishtake?
# dmesg -t | grep "^cpu. at" | sort | uniq | wc -l
# grep "^processor" cpuinfo | wc -l
# jobs should be between 1+n and 2*n where n is the number of the cores/CPUs
#
jobs=8

continuous=1 	# Ad infinitum, ad nauseum
updatecvs=1
quiet=0
keeplogs=0
updateflag="-u"
#otherflags="-P" # Does not work on Darwin
otherflags=""
buildx=0	# X Windows
withX=""

# Assume we are in the src directory
#
if [ ! -f "build.sh" ]; then
	echo "$0: must be run within the NetBSD src directory"
	exit 2
fi

sourceroot=`(cd .. && pwd)`
logdir=$sourceroot/buildlogs

USAGE="$0 [-A] [-1] [-c] [-q] [-k] [-D] [-h] [-x] [-j n] [-l logdir] 
		[-n] [targets]
  -A  build all architecture targets
  -1  just run once, not continuously
  -c  don't update CVS, implies -1 (no point in repeating otherwise)
  -q  quiet mode
  -Q  very quiet mode
  -k  keep successful logs
  -D  don't supply -u to build.sh
  -h  print this message
  -j n  supply n to -j on build.sh
  -l logdir - use alternative log dir
  -x  attempt to build X as well
  -n  don't upload logs
  targets given on the command line override -A and defaults
"

while [ $# -gt 0 ]; do
        case $1 in
	-A)	targets="$alltargets"; ;;
        -1)	continuous=0; ;;
        -j)	jobs="$2"; shift; ;;
        -l)	logdir="$2"; shift; ;;
        -c)	updatecvs=0; continuous=0; ;;
        -n)	uploadr=0; ;;
        -q)	quiet=1; ;;
        -Q)	quiet=2; ;;
        -k)	keeplogs=1; ;;
        -D)	updateflag=""; ;;
        -x)	buildx=1; ;;
        -h|--help)              
                                echo "$USAGE"; exit ;;
        -*)             echo "${0##*/}: unknown option \"$1\"" 1>&2
                          echo "$USAGE" 1>&2; exit 1 ;;
	*)	break; # rest of args are targets
	esac
	shift
done

mkdir -p "$logdir"

xflags=""
if [ "$buildx" = "1" ]; then
	if [ ! -d "$sourceroot/xsrc" ]; then
		buildx = 0;
		decho "Cannot find xsrc - won't build X"
	fi
fi
sleep 5
# Tier 1 platforms
#
#supported="amd64 i386 sparc64 evbppc hpcarm evbarm64-el evbarm64-eb evbmips64-eb evbmips64-el evbmips-eb evbmips-el"
supported="amd64 i386 sparc64 evbppc evbarm64-el evbarm64-eb"

# EVBArm combinations
#evbarmv4-el evbarmv4-eb evbarmv5-el evbarmv5hf-el evbarmv5-eb evbarmv5hf-eb evbarmv6-el evbarmv6hf-el evbarmv6-eb evbarmv6hf-eb evbarmv7-el evbarmv7-eb evbarmv7hf-el evbarmv7hf-eb evbarm64-el evbarm64-eb

# EVBMips combinations
#evbmips64-eb evbmips64-el evbmips-eb evbmips-el

# Others
#
other="sparc acorn32 cats cobalt dreamcast sun2 sun3 macppc"
#other=""

# Override
if [ $# -gt 0 ]; then
	targets="$*"
fi

# Put the releases in one place
#
export RELEASEDIR="$sourceroot/releases"

# Seperate out all objects
#
export MAKEOBJDIRPREFIX=$sourceroot'/obj/${MACHINE}${MACHINE_ARCH:N${MACHINE}:C/(.)/-\1/}'


decho() {
	dt=`date +%Y%m%d%H%M`
	[ "$quiet" != "2" ] && echo "$dt: $1"
	echo "$dt: $1" >> $masterlogfile
}

qecho() {
	dt=`date +%Y%m%d%H%M`
	echo "$dt: $1"
	echo "$dt: $1" >> $masterlogfile
}

fecho() {
	dt=`date +%Y%m%d%H%M`
	echo -n "$dt: "
	printf "\033[31;1m$1\033[0m\n"
	echo "$dt: $1" >> $masterlogfile
	echo "$dt: $1" >> $faillogfile
}


# Here we go
#

failure=0
while [ 1 = 1 ]; do
	runlogdir="$logdir/`date +%Y%m%d%H%M`"
	mkdir -p $runlogdir
	masterlogfile=$runlogdir/`date +%Y%m%d%H%M`-master.txt
	faillogfile=$runlogdir/`date +%Y%m%d%H%M`-fails.txt

	qecho "Building NetBSD sources on `hostname -s` (`uname -s`/`uname -m`/`uname -r`)"
	decho "Targets: $targets"
	decho "Failures logged to $faillogfile"

	# Update from CVS
	#
	cvslogfile="$logdir/`date +%Y%m%d%H%M`-cvsupdate.txt"

	if [ "$updatecvs" != "0" ]; then
		decho "Updating sources..."
		[ "$quiet" = "0" ] && tail -f $cvslogfile &
		cvs -q up -dP >> "$cvslogfile" 2>&1
		[ "$buildx" = "1" ] && ( cd ../xsrc && cvs -q up -dP) >> "$cvslogfile" 2>&1
	fi

	# Build each machine, then build the release
	# (separated out because the build can work but not the release)
	#
	for machine in $targets; do
	
		if [ "$buildx" = "1" ]; then
			if [ "$machine" = "sun2" ]; then
				qecho "X known broken on $machine - skipping X"
				xflags=""
				withX=""
			else
				xflags="-x -X $sourceroot/xsrc"
				withX=" with X"
			fi
		fi
		logfile="$runlogdir/`date +%Y%m%d%H%M`-$machine"".txt"
		qecho "$machine build$withX started - logging to $logfile"
		touch $logfile
		[ "$quiet" = "0" ] && tail -f $logfile &
		./build.sh -j $jobs -U $updateflag $xflags $otherflags -m $machine build >> $logfile 2>&1
		if [ "$?" != "0" ]; then
			fecho "$machine build$withX FAILED"
			failure=1
		else
			decho "$machine build$withX completed"
			qecho "$machine release$withX started"
			./build.sh -j $jobs -U -u $otherflags $xflags -m $machine release >> $logfile 2>&1
			if [ "$?" != "0" ]; then
				fecho "$machine release$withX FAILED"
				failure=1
			else
				qecho "$machine release$withX completed"
				[ "$keeplogs" = "0" ] && rm -f "$logfile"
				[ "$keeplogs" = "1" ] && gzip "$logfile"
			fi
		fi

	done
	qecho "Build completed ==="

	if [ "$uploadr" = "1" ] && [ "$failure" = "1" ]; then
		qecho "Uploading results to $uploadurl"
		scp -qr $runlogdir $uploadurl
	fi
	echo ""
	failure=0
	[ "$continuous" != "1" ] && exit 0;
done
