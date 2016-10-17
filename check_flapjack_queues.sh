#!/bin/bash
# Description: Flapjack queues check

set -x; # Enable this to enable debug mode.

MAILIST="your@email.com"

CRITICAL_events=3000
CRITICAL_notifications=1000
CRITICAL_email_notifications=200

WARNING_events=2000
WARNING_notifications=500
WARNING_email_notifications=100

QUEUES=( 'events' 'notifications' 'email_notifications' )

i=0
for QUEUE in "${QUEUES[@]}"; do

	case ${QUEUE} in
		events )
			CRITICAL=${CRITICAL_events}
			WARNING=${WARNING_events}
		;;
		notifications )
			CRITICAL=${CRITICAL_notifications}
			WARNING=${WARNING_notifications}
		;;
		email_notifications )
			CRITICAL=${CRITICAL_email_notifications}
			WARNING=${WARNING_email_notifications}
		;;
		* )
			exit
		;;
	esac

	TEST=`curl -sS --connect-timeout 10 --max-time 20 sensu.domain.com:13081/queues | jq .flapjack.queues.${QUEUE}`
	if [ -z ${TEST} ] ; then
		RESULT[${i}]=`echo "WARNING - timeout connection error: ${TEST};"`
	elif [ ${TEST} -gt ${CRITICAL} ] ; then
		RESULT[${i}]=`echo "CRITICAL - flapjack.queues.${QUEUE} = ${TEST} > ${CRITICAL};"`
	elif [ ${TEST} -gt ${WARNING} ] ; then
		RESULT[${i}]=`echo "WARNING - flapjack.queues.${QUEUE} = ${TEST} > ${WARNING};"`
	else
		RESULT[${i}]=`echo "OK - flapjack.queues.${QUEUE} = ${TEST};"`
	fi
	i=`expr $i + 1`

done

sendMailAlert ()
{
        echo "$1" | mail -r "`hostname`" -s "$2" $MAILIST
}

if [[ `echo ${RESULT[*]} | grep "CRITICAL" | wc -l` > 0 ]] ; then 
	sendMailAlert "${RESULT[*]}" "Flapjack queues CRITICAL ALERT"
elif [[ `echo ${RESULT[*]} | grep "WARNING" | wc -l` > 0 ]] ; then 
	sendMailAlert "${RESULT[*]}" "Flapjack queues WARNING ALERT"
fi
