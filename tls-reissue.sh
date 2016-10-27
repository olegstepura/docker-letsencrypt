#!/bin/bash

[ "$EUID" -ne 0 ] && { echo "Please run as root"; exit 1; }

[ -z "$1" ] && { echo >&2 "Please enter domain name as the first argument"; exit 1; }
[ -z "$2" ] && { echo >&2 "Please enter container name as the second argument"; exit 1; }

VERBOSE=0
CERT_DIR="/etc/letsencrypt/$1"
TEMP_DIR="$CERT_DIR/tmp/"

if [ "$3" == "--verbose" ]; then
	VERBOSE=1
fi

MESSAGE=$(docker start -a $2)

echo "$MESSAGE" > "$TEMP_DIR/result"

if [ -n "${MESSAGE// }" ]; then
	# Non-empty output means there was an error
	echo "TLS certificate generation error for \"$1\" with \"$2\""
	echo ""
	echo "$MESSAGE"
fi

if [ "$VERBOSE" == 1 ]; then
	cat "$CERT_DIR/$(date +"%Y-%m-%d").log" 
fi
