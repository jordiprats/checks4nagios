#!/bin/bash

wval=70
cval=80

while getopts 'd:w:c:' OPTION
do
  case $OPTION in
  w)    wval="$OPTARG"
        ;;
  c)    cval="$OPTARG"
        ;;
  d)    vflag=1
        LVDISK="$OPTARG"
        ;;
  ?)    echo Argument invalid
        exit 3
        ;;
  esac
done

if [ -z "${LVDISK}" ];
then
  echo "which docker pool do you want to check today?"
  exit 3
fi

POOLDATA=$(lvdisplay ${LVDISK} | grep "Allocated pool data" | awk '{ print $NF }' | cut -f 1 -d% | cut -f1 -d.)
POOLDATARAW=$(lvdisplay ${LVDISK} | grep "Allocated pool data" | awk '{ print $NF }')

STATUS="Allocated pool data ${POOLDATARAW} | percent=${POOLDATA};"

if [ -z "$POOLDATA" ];
then
	echo "UNKNOWN"
	exit 3;
elif [ "$POOLDATA" -ge "$cval" ];
then
	echo CRITICAL - $STATUS
	exit 2
elif [ "$POOLDATA" -ge "$wval" ];
then
	echo WARNING - $STATUS
	exit 1
else
	echo OK - $STATUS
	exit 0
fi
