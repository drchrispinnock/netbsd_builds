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
uploadr=0
removestate=0
sleepbetween=18000	# 5 hours

# Tier 1 platforms (subset)
#
supported="amd64 i386 sparc64 evbppc hpcarm evbarm64-el evbarm64-eb evbmips64-eb evbmips64-el evbmips-eb evbmips-el"

# All EVBArm combinations
#
#evbarmv4-el evbarmv4-eb evbarmv5-el evbarmv5hf-el evbarmv5-eb evbarmv5hf-eb evbarmv6-el evbarmv6hf-el evbarmv6-eb evbarmv6hf-eb evbarmv7-el evbarmv7-eb evbarmv7hf-el evbarmv7hf-eb evbarm64-el evbarm64-eb

# Tier 2/Organic platforms
#
organic="acorn32 algor alpha amiga amigappc arc atari bebox cats cesfic	cobalt dreamcast epoc32 emips evbsh3-eb evbsh3-el ews4800mips hp300 hppa hpcmips hpcsh ibmnws iyonix landisk luna68k mac68k macppc macppc64 mipsco mmeye mvme68k mvmeppc netwinder news68k newsmips next68k ofppc pmax prep rs6000 sandpoint sbmips-eb sbmips-el sbmips64-eb sbmips64-el sgimips shark sparc sun2 sun3 vax x68k zaurus"
other="ia64 riscv"

# All targets
alltargets="$supported $organic $other"

# Defaults
#
#
# Default to 1 for now, but it would be great if you could count the CPUs
# and default to 2*that...
#
# Number of CPUs - there must be a better way - shirley shome mishtake?
# dmesg -t | grep "^cpu. at" | sort | uniq | wc -l
# grep "^processor" cpuinfo | wc -l
# jobs should be between 1+n and 2*n where n is the number of the cores/CPUs
#
jobs=1

continuous=1 	# Ad infinitum, ad nauseum
updatecvs=1
quiet=0
keeplogs=0

# Update as default
updateflag="-u"

# X windows
buildx=1
withX=""

if [ "`uname -s`" = "NetBSD" ]; then
	otherflags="-P" 
	# does not work well on Darwin, not sure of others!
else
	otherflags=""
fi

# Assume we are in the src directory
#
if [ ! -f "build.sh" ]; then
	echo "$0: must be run within the NetBSD src directory"
	exit 2
fi

sourceroot=`(cd .. && pwd)`
logdir=$sourceroot/buildlogs

USAGE="$0 [-A] [-1] [-c] [-q] [-k] [-D] [-h] [-x] [-j n] [-l logdir] 
		[-n] [-Z] [-R} [targets]
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
  -x  attempt to build X as well (default)
  -X  don't build X
  -n  don't upload logs
  -Z  remove state
  -R  restart, attempt to start from state file 
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
        -X)	buildx=0; ;;
        -Z)	removestate=1; ;;
        -R)	removestate=0; ;;
        -h|--help)              
                                echo "$USAGE"; exit ;;
        -*)             echo "${0##*/}: unknown option \"$1\"" 1>&2
                          echo "$USAGE" 1>&2; exit 1 ;;
	*)	break; # rest of args are targets
	esac
	shift
done

mkdir -p "$logdir"
statefile="$logdir/statefile"

xflags=""
if [ "$buildx" = "1" ]; then
	if [ ! -d "$sourceroot/xsrc" ]; then
		echo "Cannot find xsrc - ignoring" >&2
		buildx="0"
	fi
fi
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
	removestate=1
fi

# Put the releases in one place
#
export RELEASEDIR="$sourceroot/releases"

# Seperate out all objects
#
#export MAKEOBJDIRPREFIX=$sourceroot'/obj/${MACHINE}${MACHINE_ARCH:N${MACHINE}:C/(.)/-\1/}'


date_format="%Y%m%d%H%M"
date_format="%d/%m/%Y %H:%M"

del() {
	printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
}

decho() {
	stub=""
	[ "$whatwedo" != "" ] && stub="$whatwedo "
	dt=`date +"$date_format"`
	[ "$quiet" != "2" ] && del && printf "\r$dt $stub$1"
	echo "$dt: $stub$1" >> $masterlogfile
}

qecho() {
	stub=""
	[ "$whatwedo" != "" ] && stub="$whatwedo "
	dt=`date +"$date_format"`
	del
	printf "\r$dt $stub$1"
	echo "$dt $stub$1" >> $masterlogfile
}

iecho() {
	stub=""
	[ "$whatwedo" != "" ] && stub="$whatwedo "
	dt=`date +"$date_format"`
	del
	printf "\r$dt $stub$1\n"
	echo "$dt $stub$1" >> $masterlogfile
}

fecho() {
	stub=""
	[ "$whatwedo" != "" ] && stub="$whatwedo "
	dt=`date +"$date_format"`
	del
	printf "\r$dt \033[31;1m$stub$1\033[0m\n"
	echo "$dt $stUb$1" >> $masterlogfile
	echo "$dt $stub$1" >> $faillogfile
}


# Here we go
#


previous=0
state=""
if [ "$removestate" = "1" ]; then
	rm -f "$statefile"
fi

if [ -f "$statefile" ]; then
	state=`cat $statefile`
	previous=1
fi

failure=0

firstrun=1

while [ 1 = 1 ]; do

	runlogdate=`date +%Y%m%d%H%M`
	runlogdir="$logdir/$runlogdate"
	mkdir -p $runlogdir
	whatwedo=""

	(cd $logdir; rm -f current; ln -sf $runlogdate current)

	masterlogfile=$runlogdir/`date +%Y%m%d%H%M`-master.txt
	faillogfile=$logdir/failures.txt

	targetrelease=`sh sys/conf/osrelease.sh`	# May change between builds

	total_starttime=`date +%s`

	iecho "Building NetBSD $targetrelease on `hostname -s` (`uname -s`/`uname -m`/`uname -r`)"
	iecho "Targets: $targets"
	iecho "Failures logged to $faillogfile"

	if [ "$previous" = "1" ]; then
		iecho "Detected state. Attempting to start from $state"
	else
	
		# Update from CVS
		#
		cvslogfile="$runlogdir/`date +%Y%m%d%H%M`-cvsupdate.txt"

		if [ "$updatecvs" != "0" ]; then
			decho "Updating sources..."
			[ "$quiet" = "0" ] && tail -f $cvslogfile &
			cvs -q up -dP >> "$cvslogfile" 2>&1
			[ "$buildx" = "1" ] && ( cd ../xsrc && cvs -q up -dP) >> "$cvslogfile" 2>&1

			egrep "^C" "$cvslogfile" 2>&1 >/dev/null
			if [ "$?" = "0" ]; then
				fecho "CONFLICTS IN CVS UPDATE - BAILING"
				exit 5
			fi
			
			egrep "^M" "$cvslogfile" 2>&1 >/dev/null
			if [ "$?" = "0" ]; then
				fecho "Warning - merges detected in source tree"
			fi

			egrep "^(U|P|M)" "$cvslogfile" 2>&1 >/dev/null
			if [ "$?" = "1" ]; then
				if [ "$firstrun" != "1" ]; then			
					# Second run wait
					decho "No changes in sources since last update - sleeping"
					sleep $sleepbetween
					continue

				fi	
			qecho "No changes in sources since last update"
			firstrun=0

			fi

		fi

	fi
	# Build each machine, then build the release
	# (separated out because the build can work but not the release)
	#

numberoftargets=`echo $targets | wc -w | sed 's/ //'g`
number="0"
	for machine in $targets; do

		number=`expr $number + 1`
		whatwedo="[$number/$numberoftargets] $machine"

		# Should we skip to something
		#
		if [ "$state" != "" ]; then
			[ "$state" != "$machine" ] && continue
			state=""
		fi

		echo "$machine" > $statefile

		if [ "$buildx" = "1" ]; then
#			if [ "$machine" = "sun2" ]; then
#				qecho "X known broken on $machine - skipping X"
#				xflags=""
#				withX=""
#			else
			xflags="-x -X $sourceroot/xsrc"
			withX=" with X"
#			fi
		fi
		logfile="$runlogdir/`date +%Y%m%d%H%M`-$machine"".txt"

		objdir="../objects/$machine"
		mkdir -p $objdir

		starttime=`date +%s`
		qecho "build$withX started"
		decho "logging to $logfile"
		decho "objects at $objdir"
		touch $logfile
		
		flags="-O $objdir -j $jobs -U $updateflag $xflags $otherflags -m $machine"
		[ "$quiet" = "0" ] && tail -f $logfile &
		./build.sh $flags build >> $logfile 2>&1
		if [ "$?" != "0" ]; then
			fecho "build$withX FAILED"
			failure=1
		else

			endtime=`date +%s`
			dur_s=`expr $endtime - $starttime`

			dur_m=`expr $dur_s / 60`
			dur_s=`expr $dur_s % 60`

			dur_h=`expr $dur_m / 60`
			dur_m=`expr $dur_m % 60`

			dur_m=`echo $dur_m | sed -e 's/^.$/0&/'`
			dur_s=`echo $dur_s | sed -e 's/^.$/0&/'`

			duration="$dur_h:$dur_m:$dur_s"

			partial=""
			[ "$previous" = "1" ] && partial=" (resumed)"
			iecho "build$withX completed in $duration$partial"
			qecho "release$withX started"
			./build.sh $flags release >> $logfile 2>&1
			if [ "$?" != "0" ]; then
				fecho "release$withX FAILED"
				failure=1
			else
				qecho "release$withX completed"
				[ "$keeplogs" = "0" ] && rm -f "$logfile"
				[ "$keeplogs" = "1" ] && gzip "$logfile"
			fi
		fi

		rm -f $statefile
		previous=0
	done
	total_endtime=`date +%s`
	total_dur_s=`expr $total_endtime - $total_starttime`

	total_dur_m=`expr $total_dur_s / 60`
	total_dur_s=`expr $total_dur_s % 60`

	total_dur_h=`expr $total_dur_m / 60`
	total_dur_m=`expr $total_dur_m % 60`

	total_dur_m=`echo $total_dur_m | sed -e 's/^.$/0&/'`
	total_dur_s=`echo $total_dur_s | sed -e 's/^.$/0&/'`

	iecho "Build completed === ($dur_h:$dur_m:$dur_s)"

	if [ "$uploadr" = "1" ] && [ "$failure" = "1" ]; then
		qecho "Uploading results to $uploadurl"
		scp -qr $runlogdir $uploadurl
	fi
	echo ""
	failure=0
	[ "$continuous" != "1" ] && exit 0;
done
