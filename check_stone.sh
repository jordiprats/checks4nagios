#!/bin/bash

IP="$1"
COMMUNITY="$2"

RES=$(/usr/bin/snmpget -t 1 -r 5 -m '' -v 2c -c $COMMUNITY $IP:161  .1.3.6.1.4.1.1369.6.1.1.3.0 | cut -d':' -f 2 | tr -d " ")

if [ $RES -eq 1 ]; then
	echo "OK - Tot correcte"
	exit 0
elif [ $RES -eq 5 ]; then
	echo "CRITICAL - Esta en bypass"
	exit 2
else
	echo "WARNING - Esta en algun estat poc normal: $RES"
	exit 1
fi

