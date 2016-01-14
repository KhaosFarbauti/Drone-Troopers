#!/bin/bash

########################################################################
#                           Drone-troopers                             #
########################################################################
#         Script d'automatisation pour le jeu minitroopers.fr          #
#                                                                      #
# Auteur : Khaos Farbauti Ibn Oblivion                                 #
# Licence : FCQTV ("Fais Ce Que Tu Veux")                              #
#                                                                      #
########################################################################

#############
# Fonctions #
#############

function identify {
if [ "$MDP" != "" ]
then
wget -q $GEST_COOKIE $URL_COMPTE/login?login=$COMPTE\;pass=$MDP -O /dev/null
fi
}

function maj_var {
CODE_ID=""
wget -q $GEST_COOKIE $URL_COMPTE/t/0 -O tmp/leader
if [ $? ]
then
CODE_ID=`grep levelup tmp/leader | sed -e 's/.*levelup=\(\S*\)".*/\1/g' | tail --line=1`
MONEY_DIFF=$MONEY
MONEY=`awk '/money/ { getline; print }' tmp/leader`
MONEY_DIFF=`expr $MONEY - $MONEY_DIFF 2>/dev/null`
POWER=`awk -F\> '/power/ { print $2 }' tmp/leader | awk -F\< '{ print $1 }'`
NB_TROOPER=`grep "du trooper" tmp/leader | wc -l`
if [ "$CODE_ID" != "" ]
then
echo "$COMPTE	code=$CODE_ID	argent=$MONEY (+$MONEY_DIFF)	power=$POWER	troopers=$NB_TROOPER"
else
echo "$COMPTE	(verrouillé)	argent=$MONEY (+$MONEY_DIFF)	power=$POWER	troopers=$NB_TROOPER"
fi
fi
}

function status {
if [ "$CODE_ID" != "" ]
then
LOCK_MISSION=0
COMBAT_DISPO=0
RAID_DISPO=0
MISSION_DISPO=0
wget -q $GEST_COOKIE $URL_COMPTE/hq -O tmp/hq
LOCK_MISSION=`grep unlock tmp/hq | wc -l`
COMBAT_DISPO=`grep opp tmp/hq |wc -l`
RAID_DISPO=`grep raid?chk tmp/hq |wc -l`
MISSION_DISPO=`grep mission?chk tmp/hq |wc -l`
fi
}

function unlock_mission {
if [ "$CODE_ID" != "" ]
then
if [ $MONEY -ge 5 ] && [ $LOCK_MISSION -eq 1 ]
then
wget -q $GEST_COOKIE $URL_COMPTE/unlock?mode=miss\;chk=$CODE_ID -O /dev/null
echo "$COMPTE	déblocage du mode mission"
maj_var
status
fi
fi
}


function attack {
if [ "$CODE_ID" != "" ]
then
CIBLE=0
MIN=1000
wget -q $GEST_COOKIE $URL_COMPTE/b/opp -O tmp/opp
LISTE_ID=(`awk -F'=|;' '/opp=/ {print $3}' tmp/opp`)
LISTE_POWER=(`awk -F\< '/.li...ul/ {print $1}' tmp/opp`)
i=0
y=0
for POWER_ENNEMI in ${LISTE_POWER[*]}
do
if [ $MIN -gt $POWER_ENNEMI ]
then 
MIN=$POWER_ENNEMI
y=$i
fi
i=`expr $i + 1`
done
CIBLE=${LISTE_ID[$y]}
echo "$COMPTE	attaque $CIBLE (power = $MIN)"
wget -q $GEST_COOKIE $URL_COMPTE/b/battle?opp=$CIBLE\;chk=$CODE_ID -O /dev/null
fi
}

function attack_mission {
if [ "$CODE_ID" != "" ]
then
wget -q $GEST_COOKIE $URL_COMPTE/b/mission?chk=$CODE_ID -O /dev/null
fi
}

function attack_raid {
if [ "$CODE_ID" != "" ]
then
wget -q $GEST_COOKIE $URL_COMPTE/b/raid?chk=$CODE_ID -O /dev/null
fi
}


function status_upgrade_trooper {
if [ "$CODE_ID" != "" ]
then
for troop in $(seq 0 `expr $NB_TROOPER - 1`)
do
wget -q $GEST_COOKIE $URL_COMPTE/t/$troop -O tmp/$troop
PRIX_UPGRADE=`awk '/Améliorer/ { getline;getline; print }' tmp/$troop`
if [ $MONEY -ge $PRIX_UPGRADE ]
then
echo "$COMPTE	upgrade du trooper $troop possible : $URL_COMPTE/t/$troop"
fi
done
fi
}

function status_ajout_trooper {
if [ "$CODE_ID" != "" ]
then
wget -q $GEST_COOKIE $URL_COMPTE/add -O tmp/add
PRIX_TROOPER=`awk '/Ajouter/ { getline;getline; print }' tmp/add`
if [ $MONEY -ge $PRIX_TROOPER ]
then
echo "$COMPTE	ajout de trooper possible : $URL_COMPTE/add"
fi
fi
}

#############
# Core code #
#############

for COMPTE in `cat comptes.lst`
do

MDP=`echo $COMPTE | awk -F':' '{print $2}'`
COMPTE=`echo $COMPTE | awk -F':' '{print $1}'`

MONEY=0
POWER=0
CIBLE=0
NB_TROOPER=0
MIN=1000
GEST_COOKIE="--cookies=on --load-cookies=tmp/cookie.txt --keep-session-cookies --save-cookies=tmp/cookie.txt"
URL_COMPTE="http://$COMPTE.minitroopers.fr"

echo "----------------------------------------------------------------------"

identify
maj_var
if [ "$CODE_ID" != "" ]
then

status

while [ $RAID_DISPO -gt 0 ]
do
echo "$COMPTE	lance un raid"
attack_raid
status
done


while [ $COMBAT_DISPO -gt 0 ]
do
attack
status
done

maj_var

if [ $LOCK_MISSION -eq 1 ]
then
unlock_mission
else
while [ $MISSION_DISPO -gt 0 ]
do
echo "$COMPTE	part en mission"
attack_mission
status
done
fi

maj_var

status_upgrade_trooper
status_ajout_trooper

fi
rm tmp/*

done
