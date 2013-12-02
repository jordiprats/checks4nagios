#!/bin/bash

#cosa del gerard

DBNAME="ivoox"

for last; do true; done
EXECUTE=$last

# Only will be executed if we add as last param optimize
#DBLIST=$2

# SOME INNODB TABLES REQUIRE SPECIFIC OPTIMIZE TO SKIP THE LOCKING PROBLEM playlist comment viewstoday viewsweek viewsmonth
# THE OTHER ONES ARE OPTIMIZED AS ALWAYS

SKIP_TABLES=( \`activity_backup\` \`apptype\` \`audiographrelation\` \`clicksonrelatedaudios\` \`downloads\` \`downloadsHistory\` \`downloadsStats\` \`downloads_backuo2\` \`downloads_backup\` \`downloadsh\` \`downloadshour\` \`downloadshourtmp\` \`downloadstest\`  \`likegraph\` \`mailqueue_backup3\` \`referer\` \`statsDailyAudio\` \`statsDailyChannel\` \`statsDailyProgram\` \`statsDailyUser\` \`statsDailyUser2\` \`statsMonthlyChannel\` \`statsMonthlyProgram\` \`statsMonthlyUser\` \`statsRanking\` \`statsUpload\` \`subscriptionmail\` \`suscriptionunread3\` )


TABLES_INNO=($(/usr/local/bin/mk-find -p $(cat /var/mysql/.mysql.root.pass) --engine=InnoDB --printf "%N\n" "$DBNAME"))
#TABLES_INNO=($(/usr/local/bin/mk-find -p $(cat /var/mysql/.mysql.root.pass) --engine=InnoDB --printf "%N\n" "$DBNAME" | sed 's/`/\\`/g'))
#TABLES_MY=($(/usr/local/bin/mk-find -p $(cat /var/mysql/.mysql.root.pass) --engine=MyISAM --printf "%N\n" "$DBNAME" | sed 's/`/\\`/g'))
TABLES_MY=($(/usr/local/bin/mk-find -p $(cat /var/mysql/.mysql.root.pass) --engine=MyISAM --printf "%N\n" "$DBNAME"))

TEMPF=$(mktemp /tmp/$(basename $0).XXXXXXXXXX)


for i in "${TABLES_INNO[@]}"
do

   # Busquem l'element $i i si existeix retornem un array sense aquest element. Sinó tornem el mateix element.
   CERCA=( $(echo ${SKIP_TABLES[@]##$i}) )

   if [ ${#SKIP_TABLES[@]} -eq  ${#CERCA[@]} ]; then #vol dir que NO l'ha trobat a la llista de taules que no hem de fer. Per tant l'hem d'optimitzar

      ARE_FK_REFERENCED=""

      ARE_FK_REFERENCED=$(/usr/local/mysql/bin/mysql -p$(cat /var/mysql/.mysql.root.pass) INFORMATION_SCHEMA -e \
                 "select TABLE_NAME,COLUMN_NAME,CONSTRAINT_NAME, REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME from KEY_COLUMN_USAGE where REFERENCED_TABLE_NAME =\"${i}\"")

      if [ -n "$ARE_FK_REFERENCED" ]; then
         echo "${i} HAS NOT BEEN OPTIMIZED. CHECK TABLE BECAUSE HAS FK REFERENCED AND YOU HAVE TO BE CAREFULL RUNNING pt-online-schema-change (--alter-foreign-keys-method)"
      else
         LENGTH=$((${#i}-2))
         INICI=$(date +'%s')
         if [ "$EXECUTE" = "optimize" ]; then
            #hi ha un problema que no es menja bé les cometes `taula` per solucionar-ho les trec. Té cert sentit perquè hi poden haver taules que es diguin '`taul`a'
            /usr/local/bin/pt-online-schema-change --password=$(cat /var/mysql/.mysql.root.pass) --alter "ENGINE=InnoDB" D=$DBNAME,t="${i:1:$LENGTH}" --execute >> $TEMPF
         #else # NO FA RES ES UN SIMULACRE
         #   /usr/local/bin/pt-online-schema-change --password=$(cat /var/mysql/.mysql.root.pass) --alter "ENGINE=InnoDB" D=ivoox,t="${i:1:$LENGTH}"
         fi
         FI=$(date +'%s')

         printf "%-28s %-30s %-35s\n" "Inici: $(date -d@$INICI +'%D-%T')" "${i}" "Temps total: $(($FI-$INICI)) segons"
      fi

   else
      SKIP_TABLES=( $(echo ${CERCA[@]}) )
      printf "%-28s %-30s %-35s\n" " " "${i}" "Skipping..."
#      INICI=$(date +'%s')
#      if [ "$EXECUTE" = "optimize" ]; then
#         /usr/local/mysql/bin/mysql -p$(cat /var/mysql/.mysql.root.pass) -e "optimize table ${i}" $DBNAME >> $TEMPF
#      fi
#      FI=$(date +'%s')

#      printf "%-28s %-30s %-35s\n" "Inici: $(date -d@$INICI +'%D-%T')" "${i}" "Temps total: $(($FI-$INICI)) segons"
   fi
done

# MYISAM TABLES

for i in "${TABLES_MY[@]}"
do
   CERCA=( $(echo ${SKIP_TABLES[@]##$i}) )

   if [ ${#SKIP_TABLES[@]} -eq  ${#CERCA[@]} ]; then #vol dir que NO l'ha trobat a la llista de taules que no hem de fer. Per tant l'hem d'optimitzar
      INICI=$(date +'%s')
      if [ "$EXECUTE" = "optimize" ]; then
         LENGTH=$((${#i}-2))
         /usr/local/mysql/bin/mysql -p$(cat /var/mysql/.mysql.root.pass) -e "optimize table ${i:1:$LENGTH}" $DBNAME >> $TEMPF
      fi
      FI=$(date +'%s')
      printf "%-28s %-30s %-35s\n" "Inici: $(date -d@$INICI +'%D-%T')" "${i}" "Temps total: $(($FI-$INICI)) segons"
   else
      SKIP_TABLES=( $(echo ${CERCA[@]}) )
      printf "%-28s %-30s %-35s\n" " " "${i}" "Skipping..."
   fi
done

echo -ne "\n\n\n"

cat $TEMPF

