#!/bin/bash

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

while getopts 'u:p:H:P:hb:w:c:' OPT;
do
	case $OPT in
		u)  USERNAME="$OPTARG"
		;;
		p)  PASSWORD="$OPTARG"
		;;
		H)  HOST="$OPTARG"
		;;
		P)  PORT="$OPTARG"
		;;
		h)  HELP="yes"
		;;
		b)  BUCKET="$OPTARG"
		;;
		w)  WARNING="$OPTARG"
		;;
		c)  CRITICAL="$OPTARG"
		;;
		*)  WTF="yes"
		;;
	esac
done

shift $(($OPTIND - 1))

if [ -z "$PASSWORD" ]
then
	echo "WTF?"
	exit 3
fi

WARNING=${WARNING-80}
CRITICAL=${CRITICAL-80}

MEM_PERCENTUSED=$(curl -u ${USERNAME-admin}:${PASSWORD} -X GET http://${HOST-localhost}:${PORT-8091}/pools/default/buckets/${BUCKET-default}  2>/dev/null | grep -Eo 'quotaPercentUsed":[^"]+"' | cut -f2 -d: | cut -f1 -d.)

if [ -z "${MEM_PERCENTUSED}" ];
then
	echo "CRITICAL - couchbase DOWN"
	exit 2
fi

if [ "${MEM_PERCENTUSED}" -ge "${CRITICAL}" ];
then
	echo "CRITICAL - quotaPercentUsed ${MEM_PERCENTUSED} over ${CRITICAL}|ramusage=${MEM_PERCENTUSED};"
	exit 2
fi


if [ "${MEM_PERCENTUSED}" -ge "${WARNING}" ];
then
	echo "WARNING - quotaPercentUsed ${MEM_PERCENTUSED} over ${WARNING}|ramusage=${MEM_PERCENTUSED};"
	exit 1
fi

echo "OK - quotaPercentUsed ${MEM_PERCENTUSED}|ramusage=${MEM_PERCENTUSED};"
exit 0
