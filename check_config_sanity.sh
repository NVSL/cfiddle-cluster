#!/usr/bin/bash

. assert.sh
set -e

assert_not_empty "$HEAD_ADDR" "HEAD_ADDR is not set in config.sh" 
assert_not_empty "$WORKER_ADDRS" "WORKER_ADDRS is not set in config.sh" 
assert_not_empty "$DOCKERHUB_USERNAME" "DOCKERHUB_USERNAME is not set in config.sh"


assert_true "$(grep -q auth\": ~/.docker/config.json && echo true)" "You have not authenticated with dockerhub.   Try 'docker login -u \$DOCKERHUB_USERNAME'"
