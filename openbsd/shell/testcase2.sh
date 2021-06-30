
# The actual message causing the problem
#
msg="%s konnte nicht ge\xf6ffnet werden, die Fehlermeldung lautet: %s."
msg1="%s causes a problem for some %s"
msg2="de"
msg3=""

IFS="%"
set -- %$msg
echo "Message: $msg" >&2
echo "$#" >&2

set -- %$msg1
echo "Message: $msg1" >&2
echo "$#" >&2

set -- %$msg2
echo "Message: $msg2" >&2
echo "$#" >&2

set -- %$msg3
echo "Message: $msg3" >&2
echo "$#" >&2

