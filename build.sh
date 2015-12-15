#!/bin/bash

DIR=$(dirname $(realpath $0))
. $DIR/docker-shell/shared-functions.sh

VAR=IMAGE POSSIBLE_NAME="letsencrypt" docker_enter_image_name

docker_build
