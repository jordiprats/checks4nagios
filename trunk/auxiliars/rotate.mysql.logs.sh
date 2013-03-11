#!/bin/bash

if [ ! -f /usr/local/mysql/bin/mysql ];
then
	MYSQLBIN=$(find /usr/local/mysql /opt/ /usr/local/bin/ /usr/bin/ -type f -iname mysql 2>/dev/null | head -n1)
else
	MYSQLBIN=/usr/local/mysql/bin/mysql
fi

if [ -z "$MYSQLBIN" ];
then
	echo "no trobo binari client mysql"
	exit 1
fi

if [ ! -f /usr/local/mysql/bin/mysqladmin ];
then
	MYSQLADMINBIN=$(find /usr/local/mysql /opt/ /usr/local/bin/ /usr/bin/ -type f -iname mysqladmin 2>/dev/null | head -n1)
else
	MYSQLADMINBIN=/usr/local/mysql/bin/mysqladmin
fi

if [ -z "$MYSQLADMINBIN" ];
then
	echo "no trobo binari mysqladmin"
	exit 1
fi


if [ ! -f /etc/rotatemysql.conf ]
then
	echo falta config
	exit 1
fi

source /etc/rotatemysql.conf

if [ -z "$DEFAULT_MYSQL_MAIL" ]
then
	echo default mail
	exit 2
fi

LOGNAME=$(echo "show variables like 'slow_query_log_file';" | $MYSQLBIN -u root -p$(cat /var/mysql/.mysql.root.pass) -N | tail -n1 | awk '{ print $NF }')

if [ -z "$LOGNAME" ];
then
        echo "ERROR: slowquery log NOT available"
else
        mv $LOGNAME $(dirname ${LOGNAME})/$(basename $LOGNAME).$(date +%Y%m%d)
fi

$MYSQLADMINBIN -u root -p$(cat /var/mysql/.mysql.root.pass) flush-logs

OLDLOG=$(dirname ${LOGNAME})/$(basename $LOGNAME).$(date +%Y%m%d)

for i in $(cat $OLDLOG | grep "^# User" | awk '{ print $3 }' | cut -f1 -d[ | sort | uniq)
do
	if [ -n "$(set | grep USER_MYSQL_)" ]
	then
		for e in $(set | grep USER_MYSQL_)
		do
			if [ ${e##*=} == $i ]
			then
				#mailto?
				USERMYSQLVAR=${e%%=*}
				USERNUMVAR=${USERMYSQLVAR##*_}
				MAILTO_SLOWS=$(set | grep MAIL_MYSQL_$USERNUMVAR)
				MAILTO_SLOWS=${MAILTO_SLOWS##*=}
	
				if [ -z "$MAILTO_SLOWS" ];
				then
					MAILTO_SLOWS=$DEFAULT_MYSQL_MAIL
				fi
				
				MAILTO_SLOWS=$(echo $MAILTO_SLOWS | sed "s/'//g")				
	
				# procesa slowqueries
				/usr/local/bin/mk-query-digest --filter  '($event->{user} || "") =~ m/'$i'/' $OLDLOG | mail -s "slow queries $i [$(date +%Y%m%d)]" $MAILTO_SLOWS
			fi
		done
	fi

done

if [ -z "$(set | grep USER_MYSQL_)" ]
then
	(cat $OLDLOG | grep "^# User" | awk '{ print $3 }' | cut -f1 -d[ | sort | uniq; /usr/local/bin/mk-query-digest $OLDLOG) | mail -s "slow queries - $HOSTNAME [$(date +%Y%m%d)]" $DEFAULT_MYSQL_MAIL
else
	for i in $(cat $OLDLOG | grep "^# User" | awk '{ print $3 }' | cut -f1 -d[ | sort | uniq | grep -v $(set | grep USER_MYSQL_ | awk -F= '{ print $2 }' | perl -pe 's/\n/\$\\|/' | sed 's#\\|$##'))
	do
		/usr/local/bin/mk-query-digest --filter  '($event->{user} || "") =~ m/'$i'/' $OLDLOG | mail -s "slow queries $i@$HOSTNAME [$(date +%Y%m%d)]" $DEFAULT_MYSQL_MAIL
	done
fi

if [ -n "$ADVISOR_MAIL" ];
then 
	(echo "rules:"; echo "http://www.maatkit.org/doc/mk-query-advisor.html#rules"; echo ""; /usr/local/bin/mk-query-advisor $OLDLOG) | mail -s "query advisor [$(date +%Y%m%d)]" $ADVISOR_MAIL
fi

LOGNAME=$(echo "show variables like 'log_error';" | $MYSQLBIN -u root -p$(cat /var/mysql/.mysql.root.pass) -N | tail -n1 | awk '{ print $NF }')

if [ -z "$LOGNAME" ];
then
        echo "ERROR: general log NOT available"
else
        mv $LOGNAME $(dirname ${LOGNAME})/$(basename $LOGNAME).$(date +%Y%m%d)
fi

$MYSQLADMINBIN -u root -p$(cat /var/mysql/.mysql.root.pass) flush-logs

exit 0
