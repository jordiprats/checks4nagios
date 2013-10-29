#!/bin/bash

MAX_ALLOWED_TOTAL_TIME=0.7

HOST=$1
IP=$2


if [ $# -eq 4 ]; then
   MAX_ALLOWED_TOTAL_TIME=$4
   PORT=$3
elif [ $# -eq 3 ]; then
   PORT=$3
elif [ $# -eq 2 ]; then
   PORT=80
else
   echo "Mal cridat el script $0 HOST IP [PORT [MAX-ALERT-TIME]] | connect=; ttfb=; totaltime=; size=;"
   exit 1
fi

CURL="/usr/bin/curl -s -o /dev/null -w \"Connect=%{time_connect}; TTFB=%{time_starttransfer}; Total_time=%{time_total}; Response=%{http_code}; size=%{size_download}\" -H \"Host: $HOST\" -H \"User-Agent: Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22\" http://$IP:$PORT/"


RES=$(eval $CURL)


if [ $? -ne 0 ]; then
   echo "Curl, executat incorrectament $CURL | connect=; ttfb=; totaltime=; size=;"
   exit 3
fi


eval $RES

if [ $Response = "200" ]; then
   if [ $(echo "$Total_time >= $MAX_ALLOWED_TOTAL_TIME" | bc) -eq 1 ]; then
      echo "Too much time!! Connect=$Connect TTFB=$TTFB Total_time=$Total_time size=$size| connect=$Connect; ttfb=$TTFB; totaltime=$Total_time; size=$size;"
      exit 2
   elif [ $(echo "$Total_time < $MAX_ALLOWED_TOTAL_TIME" | bc) -eq 1 ]; then
         echo "OK - Connect=$Connect TTFB=$TTFB Total_time=$Total_time size=$size| connect=$Connect; ttfb=$TTFB; totaltime=$Total_time; size=$size;"
         exit 0
   else
         echo "WARNING - Connect=$Connect TTFB=$TTFB Total_time=$Total_time size=$size| connect=$Connect; ttfb=$TTFB; totaltime=$Total_time; size=$size;"
         exit 1
   fi
else
   echo "No torna un 200| connect=; ttfb=; totaltime=; size=;"
   exit 1
fi


