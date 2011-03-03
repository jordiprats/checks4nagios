#!/bin/bash

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

LOGNAME=$(ps -fea | grep [m]ysqld | sed 's/^.*slow_query_log_file=//' | sed 's/ .*//')

if [ -z "$LOGNAME" ];
then
        echo "ERROR: slowquery log NOT available"
else
        mv $LOGNAME $(dirname ${LOGNAME})/$(basename $LOGNAME).$(date +%Y%m%d)
fi

/usr/local/mysql/bin/mysqladmin -u root -p$(cat /var/mysql/.mysql.root.pass) flush-logs

OLDLOG=$(dirname ${LOGNAME})/$(basename $LOGNAME).$(date +%Y%m%d)

for i in $(cat $OLDLOG | grep "^# User" | awk '{ print $3 }' | cut -f1 -d[ | sort | uniq)
do
	for e in $(set | grep USER_MYSQL_)
	do
		if [ ${e##*=} == $i ]
		then
			#mailto?
			USERMYSQLVAR=${e%%=*}
			USERNUMVAR=${USERMYSQLVAR##*_}
			MAILTO_SLOWS=$(set | grep MAIL_MYSQL_$MAILVAR)
			MAILTO_SLOWS=${MAILTO_SLOWS##*=}

			if [ -z "$MAILTO_SLOWS" ];
			then
				MAILTO_SLOWS=$DEFAULT_MYSQL_MAIL
			fi

			# procesa slowqueries
			/usr/local/bin/mk-query-digest --filter  '($event->{user} || "") =~ m/'$i'/' $OLDLOG | mail -s "slow queries $i [$(date +%Y%m%d)]" $MAILTO_SLOWS
		fi
	done

done

#else
for i in $(cat $OLDLOG | grep "^# User" | awk '{ print $3 }' | cut -f1 -d[ | sort | uniq | grep -v $(set | grep USER_MYSQL_ | awk -F= '{ print $2 }' | perl -pe 's/\n/\$\\|/' | sed 's#\\|$##'))
do
	/usr/local/bin/mk-query-digest --filter  '($event->{user} || "") =~ m/'$i'/' $OLDLOG | mail -s "slow queries $i@$HOSTNAME [$(date +%Y%m%d)]" $DEFAULT_MYSQL_MAIL
done

LOGNAME=$(ps -fea | grep [m]ysqld | sed 's/^.*log-error=//' | sed 's/ .*//')

if [ -z "$LOGNAME" ];
then
        echo "ERROR: general log NOT available"
else
        mv $LOGNAME $(dirname ${LOGNAME})/$(basename $LOGNAME).$(date +%Y%m%d)
fi

/usr/local/mysql/bin/mysqladmin -u root -p$(cat /var/mysql/.mysql.root.pass) flush-logs

