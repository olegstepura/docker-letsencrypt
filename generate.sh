#!/bin/bash

[ "$EUID" -ne 0 ] && { echo "Please run as root"; exit 1; }

[ -z "$1" ] && { echo >&2 "Please enter domain name as the first argument"; exit 1; }
[ -z "$2" ] && { echo >&2 "Please enter container name as the second argument"; exit 1; }

CERT_DIR="/etc/letsencrypt/$1"
BACKUP_DIR="/etc/letsencrypt/$1/backup-$(date +"%Y-%m-%d")"
TEMP_DIR="/etc/letsencrypt/$1/tmp/"

mkdir -p $BACKUP_DIR
cp $CERT_DIR/*.{key,crt} $BACKUP_DIR/

MESSAGE=$(docker start -a $2)

if [ ! -z "${MESSAGE// }" ]; then
	# Non-empty output means there was an error
	echo "$MESSAGE"
	echo ""
	echo "Will not copy new certificates to production dir due to error above"
else
	mv $TEMP_DIR/*.* $CERT_DIR/
	if /usr/sbin/nginx -t 2>&1 | grep -q "test is successful"; then 
		#  Nginx successfuly tested config, save to restart
		/bin/systemctl restart nginx.service
	else
		echo "Nginx test not passed"
		/usr/sbin/nginx -t
		echo ""
		echo "Reverting previous certificates from backup"
		cp $BACKUP_DIR/*.* $CERT_DIR/
	fi
fi

