#!/bin/bash

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

while getopts 'u:p:H:P:hm:' OPT;
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
		m)  MEMBERS="$OPTARG"
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

MEMBERS=${MEMBERS-3}

ACTIVE_MEMBERS=$(curl -u ${USERNAME-admin}:${PASSWORD} -X GET http://${HOST-localhost}:${PORT-8091}/pools/default 2>/dev/null | python -m json.tool | grep clusterMembership | grep active | wc -l)

if [ -z "${ACTIVE_MEMBERS}" ];
then
	echo "CRITICAL - server DOWN"
	exit 2
fi

if [ "${ACTIVE_MEMBERS}" -ne "${MEMBERS}" ];
then
	echo "CRITICAL - active members: ${ACTIVE_MEMBERS}|activemembers=${ACTIVE_MEMBERS};"
	exit 2
else
	echo "OK - active members: ${ACTIVE_MEMBERS}|activemembers=${ACTIVE_MEMBERS};"
	exit 0
fi
