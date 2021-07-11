
# The actual message causing the problem
#
msg="x%s konnte nicht genet werden, die Fehlermeldung lautet: %s."
msg1="%s konnte nicht genet werden, die Fehlermeldung lautet: %s."
msg2="de"
msg3=""

IFS="%"

set -- $msg
echo "Message: $msg" >&2
echo "$#" >&2

set -- x$msg1
echo "Message: $msg1"
echo " with x before" >&2
echo "$#" >&2

echo "--------" >&2
