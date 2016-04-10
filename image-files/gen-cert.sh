#!/bin/bash

#$DOMAIN is in environment
DIR=/etc/letsencrypt
# generate certs to a temp dir in case of a failure, move next if ok
DIR_CERT="$DIR/$DOMAIN/tmp"
# write all output to a log file
LOG_FILE="$DIR/$DOMAIN/$(date +"%Y-%m-%d").log"
WWW_DIR="/srv/www/"
ACCOUNT_KEY="$DIR/account.key"

DOMAIN_ALT=${DOMAIN_ALT// }
CONFIG="$(cat /etc/ssl/openssl.cnf)"
SAN_ARG=""

# If alternative domains passed, use it to generate certificate with subjectAltName
# to allow usage of single certificate for multiple domains
if [ -n "$DOMAIN_ALT" ]; then
	DOMAIN_ALT="DNS:${DOMAIN_ALT//,/,DNS:}"
	CONFIG="$CONFIG\n\n[SAN]\nsubjectAltName=$DOMAIN_ALT"
	SAN_ARG="-reqexts SAN"
fi

mkdir -pv "$DIR_CERT"

# Log output. http://stackoverflow.com/a/18462920
# this would send stdout and stderr output into the log file, but would also leave you with fd 3 connected to the console
exec 3>&1 1>>${LOG_FILE} 2>&1

if [ ! -f "$ACCOUNT_KEY" ]; then
	echo "Private key not found. Generating..."
	openssl genrsa -rand file:/dev/random 4096 > "$ACCOUNT_KEY"
	echo "Private key generated. Keep it safe."
fi

# Run batch of command each after another's successful finish, else break
echo "Generation of new certificate for '$DOMAIN' with alt '$DOMAIN_ALT' at $(date +'%Y-%m-%d %H:%M:%S')" && \
openssl genrsa -rand file:/dev/random 4096 > "$DIR_CERT/$DOMAIN.key" && \
openssl req -new -sha256 -key "$DIR_CERT/$DOMAIN.key" -subj "/CN=$DOMAIN" $SAN_ARG -config <(echo -e "$CONFIG") > "$DIR_CERT/$DOMAIN.csr" && \
python /usr/src/acme-tiny/acme_tiny.py --account-key "$ACCOUNT_KEY" --csr "$DIR_CERT/$DOMAIN.csr" --acme-dir "$WWW_DIR" > "$DIR_CERT/$DOMAIN.standalone.crt" && \
wget -O - https://letsencrypt.org/certs/isrgrootx1.pem > "$DIR_CERT/letsencrypt-intermediate.pem" && \
wget -O - https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem >> "$DIR_CERT/letsencrypt-intermediate.pem" && \
wget -O - https://letsencrypt.org/certs/lets-encrypt-x2-cross-signed.pem >> "$DIR_CERT/letsencrypt-intermediate.pem" && \
wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem >> "$DIR_CERT/letsencrypt-intermediate.pem" && \
wget -O - https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.pem >> "$DIR_CERT/letsencrypt-intermediate.pem" && \
cat "$DIR_CERT/$DOMAIN.standalone.crt" "$DIR_CERT/letsencrypt-intermediate.pem" > "$DIR_CERT/$DOMAIN.crt"

# Check if batch of commands has run successfully
RESULT=$?

if [ $RESULT -eq 0 ]; then
	# On success cleanup silently
	rm "$DIR_CERT/letsencrypt-intermediate.pem"
	rm "$DIR_CERT/$DOMAIN.standalone.crt"
	rm "$DIR_CERT/$DOMAIN.csr"

	chmod 600 -R "$DIR_CERT"

	echo "Certificates generated in '$DIR_CERT'"
	echo "Do not forget to move it to a real folder with certs"
else
	# Not successful run, output error, and log
	# This data has to be captured by script that runs docker container
	echo "Error generating certificate for '$DOMAIN' with Let's encrypt" 1>&3
	echo "" 1>&3
	cat $LOG_FILE 1>&3
fi
