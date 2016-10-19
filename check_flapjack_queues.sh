#!/bin/bash
# Author: Zoran Stefanovic
# Date: 2016-10-19
# Description: Flapjack queues check
# Ver: 0.2

#set -x; # Enable this to enable debug mode.

MAILIST="user@domain.com"

CRITICAL_events=3000
CRITICAL_notifications=1000
CRITICAL_email_notifications=200

WARNING_events=2000
WARNING_notifications=500
WARNING_email_notifications=100

declare -A RESULTS

RESPONSE=$(curl -sS --connect-timeout 10 --max-time 20 sensu.domain.com:13081/queues 2>&1)

if [[ ${?} != 0 ]]; then
	RESULT[0]=`echo "WARNING - connection error: ${RESPONSE}"`
else
	RESULTS=(
	  ['events']=$(echo ${RESPONSE} | jq '.flapjack.queues.events')
	  ['notifications']=$(echo ${RESPONSE} | jq '.flapjack.queues.notifications')
	  ['email_notifications']=$(echo ${RESPONSE} | jq '.flapjack.queues.email_notifications')
	)

	QUEUES=( 'events' 'notifications' 'email_notifications' )

	i=0
	for QUEUE in "${QUEUES[@]}"; do

		case ${QUEUE} in
			events )
				CRITICAL=${CRITICAL_events}
				WARNING=${WARNING_events}
				TEST=${RESULTS['events']}
			;;
			notifications )
				CRITICAL=${CRITICAL_notifications}
				WARNING=${WARNING_notifications}
				TEST=${RESULTS['notifications']}
			;;
			email_notifications )
				CRITICAL=${CRITICAL_email_notifications}
				WARNING=${WARNING_email_notifications}
				TEST=${RESULTS['email_notifications']}
			;;
			* )
				exit
			;;
		esac

		if [ ${TEST} -gt ${CRITICAL} ] ; then
			RESULT[${i}]=`echo "CRITICAL - flapjack.queues.${QUEUE} = ${TEST} > ${CRITICAL};"`
		elif [ ${TEST} -gt ${WARNING} ] ; then
			RESULT[${i}]=`echo "WARNING - flapjack.queues.${QUEUE} = ${TEST} > ${WARNING};"`
		else
			RESULT[${i}]=`echo "OK - flapjack.queues.${QUEUE} = ${TEST};"`
		fi
		i=`expr $i + 1`
	done
fi

sendMailAlert ()
{
	echo "$1" | mail -s "$2" $MAILIST
}

if [[ `echo ${RESULT[*]} | grep "CRITICAL" | wc -l` > 0 ]] ; then 
	sendMailAlert "${RESULT[*]}" "Flapjack queues CRITICAL ALERT"
elif [[ `echo ${RESULT[*]} | grep "WARNING" | wc -l` > 0 ]] ; then 
	sendMailAlert "${RESULT[*]}" "Flapjack queues WARNING ALERT"
fi
