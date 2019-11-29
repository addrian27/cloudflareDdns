#!/bin/bash

## DECLARE SOME CONSTANTS
X_AUTH_EMAIL="**EMAIL**"
X_AUTH_KEY="**API_KEY**"
THIS_PUB_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"


## 1 GET ZONE ID USING MAIN DOMAIN NAME
## echo $1 $2.$3

ZONES="$(curl -s -X GET -A "curl" -H "X-Auth-Email: $X_AUTH_EMAIL" -H "X-Auth-Key: $X_AUTH_KEY" -H "Content-Type: application/json" -d '{"type":"A", "name":"$3"}' "https://api.cloudflare.com/client/v4/zones")" 
ZONE_COUNT=$(echo "$ZONES" | jq '.result[].name' | wc -l)

## LOOP THROUGH ZONES MATCH THE ONE NEEDED
for  (( i=0; i<=$ZONE_COUNT-1; i++ ))
	do
		#echo $i
		ZONE_NAMES=$(echo "$ZONES" | jq '.result['$i'].name')
		#echo $NAMES
		case $ZONE_NAMES in
			*"$3"*) ZONE_ID=$(echo "$ZONES" | jq '.result['$i'].id' | cut -d "\"" -f 2)
		esac
	done

## 2 GET RECORD_ID FOR THE SUBDOMAIN
RECORD_IDS=$(curl -s -X GET -A "curl" -H "X-Auth-Email: $X_AUTH_EMAIL" -H "X-Auth-Key: $X_AUTH_KEY" -H "Content-Type: application/json" -d '{"type":"A", "name":"$2.$3"}' "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records")
RECORD_ID_COUNT=$(echo "$RECORD_IDS" | jq '.result[].name' | wc -l)

## LOOP THROUGH RECORD_IDS TO MATCH THE ONE NEEDED
for  (( i=0; i<=$RECORD_ID_COUNT-1; i++ ))
	do
		#echo $i
		ZONE_ID_NAMES=$(echo "$RECORD_IDS" | jq '.result['$i'].name')
		#echo $NAMES
		case $ZONE_ID_NAMES in
			*"$2.$3"*) RECORD_ID=$(echo "$RECORD_IDS" | jq '.result['$i'].id' | cut -d "\"" -f 2) OLD_IP=$(echo "$RECORD_IDS" | jq '.result['$i'].content' | cut -d "\"" -f 2)
		esac
	done



if [ $1 = "update" ]
then
	# update zone
	echo "UPDATING ZONE/RECORD"
	echo "ZONE ID: $ZONE_ID"
	echo "RECORD ID: $RECORD_ID"
	## 3 UPDATE WITH ZONE ID
	URL_UPDATE="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID"
	UPDATE_PAYLOAD='{"type":"A", "name":"'$2.$3'", "content":"'$THIS_PUB_IP'"}'
	#echo $UPDATE_PAYLOAD
	UPDATE_RECORD=$(curl -s -X PUT -A "curl" -H "X-Auth-Email: $X_AUTH_EMAIL" -H "X-Auth-Key: $X_AUTH_KEY" -H "Content-Type: application/json" -d "$UPDATE_PAYLOAD" "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" | jq '.success')
	echo "ZONE STATUS: "$UPDATE_RECORD
else
	# just print
	#echo "print"
	echo "ZONE ID: $ZONE_ID"
	echo "RECORD ID: $RECORD_ID"
	echo "OLD IP: $OLD_IP"
fi


