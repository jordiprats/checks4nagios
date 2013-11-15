#!/bin/bash

DBNAME="TODO!!!"

for last; do true; done
EXECUTE=$last

# Only will be executed if we add as last param optimize
#DBLIST=$2

# SOME INNODB TABLES REQUIRE SPECIFIC OPTIMIZE TO SKIP THE LOCKING PROBLEM playlist comment viewstoday viewsweek viewsmonth
# THE OTHER ONES ARE OPTIMIZED AS ALWAYS


TABLES_INNO=($(/usr/local/bin/mk-find -p $(cat /var/mysql/.mysql.root.pass) --engine=InnoDB --printf "%N\n" "$DBNAME" | tr -d '`'))
TABLES_MY=($(/usr/local/bin/mk-find -p $(cat /var/mysql/.mysql.root.pass) --engine=MyISAM --printf "%N\n" "$DBNAME" | tr -d '`'))

TEMPF=$(mktemp /tmp/$(basename $0).XXXXXXXXXX)


for i in "${TABLES_INNO[@]}"
do

   if [ "${i}" = "playlist" ] || [ "${i}" = "comment" ] || [ "${i}" = "viewstoday" ] || [ "${i}" = "viewsweek" ] || [ "${i}" = "viewsmonth" ]; then

      ARE_FK_REFERENCED=""

      ARE_FK_REFERENCED=$(/usr/local/mysql/bin/mysql -p$(cat /var/mysql/.mysql.root.pass) INFORMATION_SCHEMA -e \
                 "select TABLE_NAME,COLUMN_NAME,CONSTRAINT_NAME, REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME from KEY_COLUMN_USAGE where REFERENCED_TABLE_NAME =\"${i}\"")

      if [ -n "$ARE_FK_REFERENCED" ]; then
         echo "${i} HAS NOT BEEN OPTIMIZED. CHECK TABLE BECAUSE HAS FK REFERENCED AND YOU HAVE TO BE CAREFULL RUNNING pt-online-schema-change (--alter-foreign-keys-method)"
      else
         INICI=$(date +'%s')
         if [ "$EXECUTE" = "optimize" ]; then
            /usr/local/bin/pt-online-schema-change --password=$(cat /var/mysql/.mysql.root.pass) --alter "ENGINE=InnoDB" D=ivoox,t="${i}" --execute >> $TEMPF
         fi
         FI=$(date +'%s')

         printf "%-28s %-30s %-35s\n" "Inici: $(date -d@$INICI +'%D-%T')" "${i}" "Temps total: $(($FI-$INICI)) segons"
      fi

   else
      INICI=$(date +'%s')
      if [ "$EXECUTE" = "optimize" ]; then
         /usr/local/mysql/bin/mysql -p$(cat /var/mysql/.mysql.root.pass) -e "optimize table ${i}" $DBNAME >> $TEMPF
      fi
      FI=$(date +'%s')

      printf "%-28s %-30s %-35s\n" "Inici: $(date -d@$INICI +'%D-%T')" "${i}" "Temps total: $(($FI-$INICI)) segons"
   fi
done

# MYISAM TABLES

for i in "${TABLES_MY[@]}"
do
   INICI=$(date +'%s')
   if [ "$EXECUTE" = "optimize" ]; then
      /usr/local/mysql/bin/mysql -p$(cat /var/mysql/.mysql.root.pass) -e "optimize table ${i}" $DBNAME >> $TEMPF
   fi
   FI=$(date +'%s')
   printf "%-28s %-30s %-35s\n" "Inici: $(date -d@$INICI +'%D-%T')" "${i}" "Temps total: $(($FI-$INICI)) segons"
done

echo -ne "\n\n\n"

cat $TEMPF
rm $TEMPF

