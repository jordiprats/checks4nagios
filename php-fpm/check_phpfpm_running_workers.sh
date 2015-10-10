#!/bin/bash

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

CGIFCGI=$(which cgi-fcgi)
if [ -z "$CGIFCGI" ];
then
	echo WTF? install cgi-fcgi
	exit 3
fi

while getopts 'u:p:h:w:c:p:' OPT;
do
	case $OPT in
		u)  URL="$OPTARG"
		;;
		p)  PORT="$OPTARG"
		;;
		h)  HOST="$OPTARG"
		;;
		w)  WARNING="$OPTARG"
		;;
		c)  CRITICAL="$OPTARG"
		;;
		p)  POOLFILE="$OPTARG"
		;;
		*)  WTF="yes"
		;;
	esac
done

shift $(($OPTIND - 1))

STATUSFILE=$(mktemp /tmp/phprunningprocs.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)

URL=${URL-/php-status}
HOST=${HOST-127.0.0.1}
PORT=${PORT-9000}
WARNING=${WARNING-70}
CRITICAL=${CRITICAL-80}
POOLFILE=${POOLFILE-/etc/php5/fpm/pool.d/www.conf}

SCRIPT_NAME="${URL}" \
SCRIPT_FILENAME="${URL}" \
QUERY_STRING="full" \
REQUEST_METHOD=GET \
cgi-fcgi -bind -connect ${HOST}:${PORT} > $STATUSFILE

if [ -z "$(cat $STATUSFILE)" ];
then
	echo "CRITICAL - unable to connect"
	exit 2
fi


MAXPROC=$(grep "^pm.max_children" $POOLFILE | awk '{ print $NF }')
ACTIVEPROC=$(grep "^state" $STATUSFILE | grep -i running | wc -l)

if [ -z "$MAXPROC" ] || [ -z "$ACTIVEPROC" ];
then
	echo "CRITICAL - bad input values ${MAXPROC} ${ACTIVEPROC} - check php status page"
	exit 2
fi

case $MAXPROC in
  ''|*[!0-9]*)  echo CRITICAL - MAXPROC bad value
  ;;
esac

case $ACTIVEPROC in
  ''|*[!0-9]*)  echo CRITICAL - ACTIVEPROC bad value
  ;;
esac


PROCUSAGE=$(echo "($ACTIVEPROC/$MAXPROC)*100" | bc -l | sed 's/^\([0-9]\+\)[^0-9]*.*/\1/')

if [ -z "${PROCUSAGE}" ];
then
	echo "UNKNOWN - check retrieved values"
	exit 2
fi

if [ "${PROCUSAGE}" -ge "${CRITICAL}" ];
then
	echo "CRITICAL - running workers ${PROCUSAGE}% over ${CRITICAL}%|rworkers=${PROCUSAGE};"
	exit 2
fi


if [ "${PROCUSAGE}" -ge "${WARNING}" ];
then
	echo "WARNING - running workers ${PROCUSAGE}% over ${WARNING}%|rworkers=${PROCUSAGE};"
	exit 1
fi

echo "OK - running workers ${PROCUSAGE}%|rworkers=${PROCUSAGE};"
exit 0


rm -f $STATUSFILE
