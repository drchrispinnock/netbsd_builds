cd usr/src

echo "===> Building test $machine build" >&2
sleep 1

./build.sh -j $jobs -U -m $machine build > ../../build-log 2>&1
[ "$?" != "0" ] && echo "Error building!" >&2 && exit 1

echo "===> Building test $machine release" >&2
sleep 1

./build.sh -j $jobs -U -m $machine release > ../../release-log 2>&1
[ "$?" != "0" ] && echo "Error building release!" >&2 && exit 1

# Need to preserve the logs somewhere
#
