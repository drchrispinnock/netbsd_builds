
# The actual message causing the problem
#
msg="%s konnte nicht ge\xf6ffnet werden, die Fehlermeldung lautet: %s."
msg1="%s causes a problem for some %s"
msg2="and %s does not %s"

IFS="%"
set -- - x$msg
echo "Message: $msg" >&2
echo "$#" >&2

set -- - x$msg1
echo "Message: $msg1" >&2
echo "$#" >&2

set -- - x$msg2
echo "Message: $msg2" >&2
echo "$#" >&2

set -- - "x$msg"
echo "Quoted: $msg" >&2
echo "$#" >&2

set -- - "x$msg1"
echo "Quoted: $msg1" >&2
echo "$#" >&2

set -- - "x$msg2"
echo "Quoted: $msg2" >&2
echo "$#" >&2
