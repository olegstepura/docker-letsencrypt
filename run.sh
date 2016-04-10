#!/bin/bash

DIR=$(dirname $(realpath $0))
. $DIR/docker-shell/shared-functions.sh

VAR=DOMAIN DESC="domain" docker_enter_value
export DOSKER_SHELL_ID="letsencrypt-$DOMAIN"
# Got rid of ipv6.$DOMAIN since letsencrypt was unable to fetch data for IPv6-only domain
VAR=DOMAIN_ALT DESC="alternative domain names, comma separated" PROMPT="Alternative domains" PLACEHOLDER="www.$DOMAIN,mail.$DOMAIN" docker_enter_value
VAR=IMAGE docker_select_image
VAR=CONTAINER_NAME IMAGE="$IMAGE-${DOMAIN//\./\-}" docker_enter_container_name
VAR=DOCUMENT_ROOT DESC="document root" PLACEHOLDER="/docker/letsencrypt/acme-challenge/" docker_enter_dir
VAR=CERT_DIR DESC="certificate location" PLACEHOLDER="/etc/letsencrypt/" docker_enter_dir 

ARGUMENTS="--volume $DOCUMENT_ROOT:/srv/www --volume $CERT_DIR:/etc/letsencrypt/ --env DOMAIN='$DOMAIN' --env DOMAIN_ALT='$DOMAIN_ALT'" docker_run

