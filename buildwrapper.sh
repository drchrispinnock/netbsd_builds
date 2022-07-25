#!/bin/sh
#
# Build several platforms of NetBSD in a continous loop

# Platforms - loads of defaults ##########################################
#

# My preferred targets
#
mypref="amd64 i386 sparc64 evbppc hpcarm evbmips64-eb evbarmv4-el evbarmv5-el evbarmv6-el alpha macppc riscv"
targets="$mypref" # Default

hostos=`uname -s`

# Host specific things here
#
if [ "$hostos" = "Darwin" ]; then
	MKDEBUGTOOLS=no		# yes breaks Darwin builds
fi


# Environment variables
#
[ -z "$MKDEBUG" ] && MKDEBUG=no
[ -z "$MKDEBUGKERNEL" ] && MKDEBUGKERNEL=no
[ -z "$MKDEBUGTOOLS" ] && MKDEBUGTOOLS=no
export MKDEBUG MKDEBUGKERNEL MKDEBUGTOOLS

# NFS doesn't work for all, so provide somewhere to copy webresults
#
copywebresultsroot=""
copywebresults=0

# My Hostname and platform
#
hostname=`hostname -s | tr "[:upper:]" "[:lower:]"`
os=`uname -s`
hostmach=`uname -m`
osres=`uname -r`
webresultshostname=$hostname

# Don't remove the state (default) - the state allows the script
# to pick up from where it left off, sort of.
#
removestate=0

# Sleep between cycles when there is nothing to do
# due to no CVS updates
#
sleepbetween=18000	# 5 hours

# Tier 1 platforms (subset)
#
supported="amd64 i386 sparc64 evbppc hpcarm evbmips64-eb evbmips64-el evbmips-eb evbmips-el"

# Tier 1 - All EVBArm combinations
#
evbarm="evbarmv4-el evbarmv4-eb evbarmv5-el evbarmv5hf-el evbarmv5-eb evbarmv5hf-eb evbarmv6-el evbarmv6hf-el evbarmv6-eb evbarmv6hf-eb evbarmv7-el evbarmv7-eb evbarmv7hf-el evbarmv7hf-eb evbarm64-el evbarm64-eb"

# Tier 2/Organic platforms
#
organic="acorn32 algor alpha amiga amigappc arc atari bebox cats cesfic cobalt dreamcast epoc32 emips evbsh3-eb evbsh3-el ews4800mips hp300 hppa hpcmips hpcsh ibmnws iyonix landisk luna68k mac68k macppc mipsco mmeye mvme68k mvmeppc netwinder news68k newsmips next68k ofppc pmax prep rs6000 sandpoint sbmips-eb sbmips-el sbmips64-eb sbmips64-el sgimips shark sparc sun2 sun3 vax x68k zaurus"

# Others
#
other="macppc64 ia64 riscv"

# All targets
#
alltargets="$supported $evbarm $organic $other"

# Jobs
#
# Default to 1 for now, but it would be great if you could count the CPUs
# and default to 2*that...
#
# Number of CPUs
# dmesg -t | grep "^cpu. at" | sort | uniq | wc -l
# grep "^processor" cpuinfo | wc -l
# jobs should be between 1+n and 2*n where n is the number of the cores/CPUs
#
jobs=1

# By default, keep going ad infinitum, ad nauseum
continuous=1 	

# Update sources before starting
updatecvs=1

# Suppress output
quiet=0

# Keep logs even if success (lots of disc space)
keeplogs=0

# pass -u to build.sh to not clean everything
#
updateflag="-u"

# Cleanups
#
cleandest="0"
cleanobj="0"
cleanafter="0"

# Retry on fail
#
retryonfail=0

# make target (build or release, etc)
#
make_target=build

# Build X windows if the sources are available
buildx=1
withX=""

# Christos fixed -P by toolifying date 26/5/2021
#
otherflags="-P" 

# Assume we are in the src directory
#
if [ ! -f "build.sh" ]; then
	echo "$0: must be run within the NetBSD src directory"
	exit 2
fi

sourceroot=`(cd .. && pwd)`
logdir=$sourceroot/buildlogs

# Directory for outputting results files for a web interface
#
webresultsroot="$sourceroot/buildres"
webresults=1
branch=""

USAGE="$0 [-A] [-1] [-c] [-q] [-k] [-D] [-h] [-x] [-j n] [-l logdir] 
		[ -t build|release] [-n] [-Z] [-R] [-r] [-W] [-w webroot] [targets]
  -A  build all architecture targets
  -1  just run once, not continuously
  -c  don't update source on first build run
  -q  very quiet mode
  -Q  headless
  -k  keep successful logs
  -D  don't supply -u to build.sh
  -h  print this message
  -j n  supply n to -j on build.sh
  -l logdir - use alternative log dir
  -x  attempt to build X as well (default)
  -X  don't build X
  -n  don't upload logs
  -t  make target (e.g. build, release - default is build)
  -Z  remove statefile
  -R  restart, attempt to start from state file 
  -r  retry build with empty object directory if failure
  -e  erase destdir before builds
  -E  erase objects before builds
  -F  erase objects after builds (e.g. short disc space)
	
Web reporting options:
  -W don't output web results
  -w webroot - build web results into the specified directory
	-b branch - display the branch ID instead of the source date
  -H hostid - use a different hostname for segregating & outputting results
  -y webroottarget - copy the web results to a server via SSH
  targets given on the command line override -A and defaults
"

cmdline="$0 $@"

while [ $# -gt 0 ]; do
        case $1 in
	-A)	targets="$alltargets"; ;;
        -1)	continuous=0; ;;
        -j)	jobs="$2"; shift; ;;
        -l)	logdir="$2"; shift; ;;
        -c)	updatecvs=0; ;;
        -n)	uploadr=0; ;;
        -t)	make_target="$2"; shift; ;;

# Logging options
#
        -q)	quiet=2; ;;
        -Q)	quiet=3; ;;
        -k)	keeplogs=1; ;;

# Don't pass -u
#
        -D)	updateflag=""; ;;
# To build X or not
#
        -x)	buildx=1; ;;
        -X)	buildx=0; ;;

# To preserve state from the last run or not
#
        -Z)	removestate=1; ;;
        -R)	removestate=0; ;;

# Retry the build with an empty object directory
#
        -r)	retryonfail=1; ;;

# Erasure
#
        -e)	cleandest="1"; ;;
        -E)	cleanobj="1"; ;;
	-F)	cleanafter="1"; ;;

# Web results
				-b) branch="$2"; shift; ;;
				-H) webresultshostname="$2"; shift; ;;
				-W) webresults=0; ;;
				-w) webresultsroot="$2"; shift; webresults=1; ;;
				-y) copywebresultsroot="$2"; shift; 
						webresultsroot="$sourceroot/buildres"; 
						copywebresults=1; ;;



# Help!
        -h|--help)	echo "$USAGE"; exit ;;
        -*)					echo "${0##*/}: unknown option \"$1\"" 1>&2
                    echo "$USAGE" 1>&2; exit 1 ;;
	*)	break; # rest of args are targets
	esac
	shift
done

# Web results directory
#
webresultstarget="$webresultsroot/$webresultshostname"

# Make the log directory
#
mkdir -p "$logdir"
statefile="$logdir/statefile"

# CMDline
#
echo "$cmdline" > $logdir/command_line.sh

# Check for x sources
xflags=""
if [ "$buildx" = "1" ] && [ ! -d "$sourceroot/xsrc" ]; then
	[ "$quiet" != "3" ] && echo "Cannot find xsrc - ignoring" >&2
	buildx="0"
fi

# Override targets from the CLI (overrides -A)
#
if [ $# -gt 0 ]; then
	targets="$*"
	removestate=1
fi

# Put the releases in one place
#
export RELEASEDIR="$sourceroot/releases"

# Logging date format
#
#date_format="%Y%m%d%H%M"
date_format="%d/%m/%Y %H:%M"

makewebresultsdir() {
	mkdir -p "$webresultstarget/build"
	mkdir -p "$webresultstarget/logs"
}

outputwebdetail() {
	# $targetrelease $os $hostmach $osres $maketarget $withX
	#
	outputthefile=0
	[ "$webresults" = "1" ] && outputthefile=1;
	[ "$previous" = "0" ] && outputthefile=1;
	[ ! -f "$webresultstarget/detail.txt" ] && outputthefile=1;
	[ "$webresults" = "0" ] && outputthefile=0;

	param="$5 without X"
	if [ "$6" = "1" ]; then
		param="$5 with X"
	fi
	
	if [ "$webresults" = "1" ]; then
		
		makewebresultsdir
		echo "target|$1" > "$webresultstarget/detail.txt"
		echo "hostname|$webresultshostname" >> "$webresultstarget/detail.txt"
		echo "hostos|$2" >> "$webresultstarget/detail.txt"
		echo "hostmach|$3" >> "$webresultstarget/detail.txt"
		echo "hostver|$4" >> "$webresultstarget/detail.txt"
		echo "builddate|$7" >> "$webresultstarget/detail.txt"
		echo "param|$param" >> "$webresultstarget/detail.txt"
		echo "maketarget|$5" >> "$webresultstarget/detail.txt"
		echo "withX|$6" >> "$webresultstarget/detail.txt"
	fi
	
}

outputwebcvs() {
# $cvsdate
	if [ "$webresults" = "1" ]; then
		makewebresultsdir
		echo "$1" > "$webresultstarget/cvsdate.txt"
	fi
}

cleanwebip() {
	# clean up the in progress files
	if [ -d "$webresultstarget/build" ]; then
		cleanlist=`grep -l 'status|PROG' "$webresultstarget"/build/* 2>&1 >/dev/null`
		for f in $cleanlist; do
			rm -f $f
		done
fi
}

webresult() {
	# Expects 3 arguments: Machine, Status, build date Logfile

	if [ "$webresults" = "1" ]; then
		
		echo "status|$2" > "$webresultstarget/build/$machine"
		echo "version|$targetrelease" >> "$webresultstarget/build/$machine"
		echo "builddate|$3" >> "$webresultstarget/build/$machine"
		echo "date|`date +%d/%m/%Y`" >> "$webresultstarget/build/$machine"

		# Remove old logs
		#
		rm -f $webresultstarget/logs/${machine}-full.txt
		rm -f $webresultstarget/logs/${machine}-tail.txt
		
		if [ "$4" != "" ]; then
			#			cp "$4" "$webresultstarget/logs/${machine}-full.txt"
			tail -500 "$4" > "$webresultstarget/logs/${machine}-tail.txt"
		fi
		
		
		if [ "$copywebresults" = "1" ]; then
			rsync -aqz -e "ssh -q" --delete "$webresultstarget" "$copywebresultsroot/" 
		fi
	fi

}

# Clear a line
del() {
	printf "\r                                                                             ";
}

decho() {
	stub=""
	[ "$whatwedo" != "" ] && stub="$whatwedo "
	dt=`date +"$date_format"`
	if [ "$quiet" != "2" ] && [ "$quiet" != "3" ]; then
		del && printf "\r$dt $stub$1"
	fi
	echo "$dt: $stub$1" >> $masterlogfile
}

# Even if quiet
#
qecho() {
	stub=""
	[ "$whatwedo" != "" ] && stub="$whatwedo "
	dt=`date +"$date_format"`
	if [ "$quiet" != "3" ]; then
		del
		printf "\r$dt $stub$1"
	fi
	echo "$dt $stub$1" >> $masterlogfile
}

# Informational
#
iecho() {
	stub=""
	[ "$whatwedo" != "" ] && stub="$whatwedo "
	dt=`date +"$date_format"`
	if [ "$quiet" != "3" ]; then 
		del
		printf "\r$dt $stub$1\n"
	fi
	echo "$dt $stub$1" >> $masterlogfile
}

# Fail - print in red
fecho() {
	stub=""
	[ "$whatwedo" != "" ] && stub="$whatwedo "
	dt=`date +"$date_format"`
	if [ "$quiet" != "3" ]; then
		del
		printf "\r$dt \033[31;1m$stub$1\033[0m\n"
	fi
	echo "$dt $stub$1" >> $masterlogfile
	echo "$dt $stub$1" >> $faillogfile
}


# Here we go
#

# Deal with state
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

firstrun=1 # used for source checks

while [ 1 = 1 ]; do

	failure=0
	runlogdate=`date +%Y%m%d-%H%M`
	runlogdir="$logdir/$runlogdate"
	mkdir -p $runlogdir
	whatwedo=""

	(cd $logdir; rm -f last; mv -f current last; ln -sf $runlogdate current)

	masterlogfile=$runlogdir/`date +%Y%m%d%H%M`-master.txt
	faillogfile=$logdir/failures.txt


	total_starttime=`date +%s`

	iecho "Starting $make_target"
	iecho "Targets: $targets"
	iecho "Failures logged to $faillogfile"

	# Clean up in progress web reports
	cleanwebip;

	if [ "$previous" = "1" ]; then
		iecho "Detected state. Attempting to start from $state"
	else
	
		# Update from source
		#
		cvsdate=`date +%Y%m%d-%H%M`
		cvslogfile="$runlogdir/$cvsdate-cvsupdate.txt"
		pubcvsdate=`date +"%d/%m/%Y %H:%M"`

		
		if [ "$updatecvs" != "0" ]; then

			outputwebcvs "$pubcvsdate"
			iecho "Updating src from cvs..."
			[ "$quiet" = "0" ] && tail -f $cvslogfile &
			cvs -q up -dP >> "$cvslogfile" 2>&1
			
			if [ "$?" != "0" ]; then
				fecho "cvs update failed - bailing"
				exit 6
			fi

			if [ "$buildx" = "1" ]; then 
				iecho "Updating xsrc from cvs..."
				( cd ../xsrc && cvs -q up -dP) >> "$cvslogfile" 2>&1
				if [ "$?" != "0" ]; then
					fecho "cvs update failed - bailing"
					exit 6
				fi
			fi

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
					iecho "No changes in sources since last update - sleeping"
					sleep $sleepbetween
					continue

				fi	
			qecho "No changes in sources since last update"
			firstrun=0

			fi

		fi
	fi
	[ "$branch" != "" ] && outputwebcvs $branch
	
	targetrelease=`sh sys/conf/osrelease.sh`	# May change between builds
	iecho "Building NetBSD $targetrelease on $hostname ($os/$hostmach/$osres)"
	
	if [ "$buildx" = "1" ]; then
		xflags="-x -X $sourceroot/xsrc"
		withX=" with X"
	fi
	
	outputwebdetail $targetrelease $os $hostmach $osres "$make_target" $buildx $runlogdate

	# Build each machine target
	#
	numberoftargets=`echo $targets | wc -w | sed 's/ //'g`
	number="0"

	for machine in $targets; do
		cleandest_this=$cleandest	
		cleanobj_this=$cleanobj

		number=`expr $number + 1`
		whatwedo="[$number/$numberoftargets] $machine"

		failure=0

		# Should we skip to something
		#
		if [ "$state" != "" ]; then
			[ "$state" != "$machine" ] && continue
			# if we are skipping to state, don't clean
			cleandest_this=0
			cleanobj_this=0
			state=""
		fi

		echo "$machine" > $statefile
			

		# Machine exceptions
		#
		if [ "$machine" = "sun2" ]; then
			qecho "X known broken on $machine - skipping X"
			xflags=""
			withX=""
		fi
		
		logfile="$runlogdir/`date +%Y%m%d%H%M`-$machine"".txt"

		objdir="../objects/$machine"
		mkdir -p $objdir

		starttime=`date +%s`
		qecho "$make_target$withX started"
		decho "logging to $logfile"
		decho "objects at $objdir"
		touch $logfile
		webresult $make_target "PROG" $runlogdate ""

		if [ "$cleandest_this" = "1" ]; then
			decho "Cleaning $objdir/destdir for $machine"
			rm -rf "$objdir/destdir"*
		fi

		if [ "$cleanobj_this" = "1" ]; then
			decho "Cleaning objects for $machine"
			rm -rf "$objdir"
		fi
		
		flags="-O $objdir -j $jobs -U $updateflag $xflags $otherflags -m $machine"
		[ "$quiet" = "0" ] && tail -f $logfile &

		./build.sh $flags $make_target >> $logfile 2>&1
		if [ "$?" != "0" ]; then
			fecho "$make_target$withX FAILED"
			failure=1
			if [ "$retryonfail" = "1" ]; then
				failure=0
				decho "Cleaning objects for $machine"
				rm -rf "$objdir"
				flags="-O $objdir -j $jobs -U $xflags $otherflags -m $machine"
				qecho "$make_target$withX restarted from scratch"
				./build.sh $flags $make_target >> $logfile 2>&1
				if [ "$?" != "0" ]; then
					fecho "$make_target$withX FAILED FROM CLEAN"
					failure=1
					webresult $make_target "FAIL" $runlogdate "$logfile"
				fi
			else
				webresult $make_target "FAIL" $runlogdate "$logfile" 
			fi

		fi

		if [ "$failure" != "1" ]; then

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
			iecho "$make_target$withX completed in $duration$partial"
			webresult $make_target "OK" $runlogdate "$logfile" 
			[ "$keeplogs" = "0" ] && rm -f "$logfile"
			[ "$keeplogs" = "1" ] && gzip "$logfile"
		fi

		rm -f $statefile
		previous=0
		if [ "$cleanafter" = "1" ]; then
			decho "Cleaning objects post-build for $machine"
			rm -rf "$objdir"
		fi
		
		
	done
	total_endtime=`date +%s`
	total_dur_s=`expr $total_endtime - $total_starttime`

	total_dur_m=`expr $total_dur_s / 60`
	total_dur_s=`expr $total_dur_s % 60`

	total_dur_h=`expr $total_dur_m / 60`
	total_dur_m=`expr $total_dur_m % 60`

	total_dur_m=`echo $total_dur_m | sed -e 's/^.$/0&/'`
	total_dur_s=`echo $total_dur_s | sed -e 's/^.$/0&/'`

	whatwedo=""
	iecho "Build completed === ($total_dur_h:$total_dur_m:$total_dur_s)"

	echo ""

	# If we are a one shot pony, let's exit here
	[ "$continuous" != "1" ] && exit 0;

	if [ "$softwareupdate" = "1" ]; then
		where=`pwd`
		cd `dirname $0` && git pull
		cd $where && $logdir/command_line.sh &
		exit 0
	fi

	updatecvs=1 # Update CVS next time regardless
done
