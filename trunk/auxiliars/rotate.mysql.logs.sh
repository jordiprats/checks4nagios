#!/bin/bash

#set -xv

#LOGNAME=$(ps -fea | grep [m]ysqld | sed 's/^.*slow_query_log_file=//' | sed 's/ .*//')
LOGNAME=$(echo "show variables like 'slow_query_log_file';" | /usr/local/mysql/bin/mysql -u root -p$(cat /var/mysql/.mysql.root.pass) | tail -n1 | awk '{ print $NF }')

if [ -z "$LOGNAME" ];
then
        echo "ERROR: slowquery log NOT available"
else
        mv $LOGNAME $(dirname ${LOGNAME})/gi-$(basename $LOGNAME).$(date --date="1 week ago" +%Y%m%d)_$(date +%Y%m%d)
fi

#LOGNAME=$(ps -fea | grep [m]ysqld | sed 's/^.*log-error=//' | sed 's/ .*//')
LOGNAME=$(echo "show variables like 'log_error';" | /usr/local/mysql/bin/mysql -u root -p$(cat /var/mysql/.mysql.root.pass) | tail -n1 | awk '{ print $NF }')

if [ -z "$LOGNAME" ];
then
        echo "ERROR: general log NOT available"
else
        mv $LOGNAME $(dirname ${LOGNAME})/$(basename $LOGNAME).$(date --date="1 week ago" +%Y%m%d)_$(date +%Y%m%d)
fi

/usr/local/mysql/bin/mysqladmin -u root -p$(cat /var/mysql/.mysql.root.pass) flush-logs


