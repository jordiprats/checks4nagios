#!/bin/sh

#set -xv 
#exec >/tmp/enlargeyourpenis 2>&1

HOST=$1
USER=$2
PASS=$3

EXPIRA=$(/usr/local/bin/expire-f5-license $HOST $USER $PASS | grep "^License" | awk '{ print $NF }')

if [ -z "$EXPIRA" ];
then
	echo "CRITICIAL - no obtinc resultat del f5, necesito viagra"
	exit 2
fi

EXPIRA_EPOCH=$(date -d $EXPIRA +%s)
ARA=$(date +%s)
QUEDEN=$(($EXPIRA_EPOCH-$ARA))

UNDIA=86400
DOSDIES=172800
TRESDIES=259200
QUATREDIES=345600
SISDIES=518400
UNASETMANA=604800


#if [ $QUEDEN -lt $UNDIA ]; then
#	echo "Falta menys d'un dia perquè caduqui el Strongbox! Caduca: $EXPIRA"
#	exit 2
#elif [ $QUEDEN -lt $DOSDIES ]; then
#	echo "Falta menys de 2 dies perquè caduqui el Strongbox! Caduca: $EXPIRA"
#	exit 2
#elif [ $QUEDEN -lt $TRESDIES ]; then
#	echo "Falta menys de 3 dies perquè caduqui el Strongbox! Caduca: $EXPIRA"
#	exit 2
#elif [ $QUEDEN -lt $QUATREDIES ]; then
#	echo "Falta menys de 4 dies perquè caduqui el Strongbox! Caduca: $EXPIRA"
#	exit 1
#elif [ $QUEDEN -lt $UNASETMANA -a $QUEDEN -gt $SISDIES ]; then
#	echo "Falta menys d'una setmana perquè caduqui el stronbox! Caduca: $EXPIRA"
#	exit 1
#fi

if [ $QUEDEN -lt $TRESDIES ]; then
        echo "ALERTA - Falta menys de $(($QUEDEN/$UNDIA)) dies perquè caduqui el Strongbox! Caduca el: $EXPIRA"
        exit 2
fi

if [ $QUEDEN -lt $UNASETMANA ]; then
	echo "AVÍS - Falta menys de $(($QUEDEN/$UNDIA)) dies perquè caduqui el stronbox! Caduca el: $EXPIRA"
        exit 1
fi


echo -en "OK - queden $(($QUEDEN/$UNDIA)) dies i escaig "
#echo -n 8; for i in $(seq 1 $(($QUEDEN/$UNDIA))); do echo -n =; done; echo D
exit 0

