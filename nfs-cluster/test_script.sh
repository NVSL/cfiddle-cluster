#!/usr/bin/env bash


while true; do
    (set -x;
    [ -e /users_home/existed_before ] || echo failed
    touch /users_home/existed_after || echo failed
    [ -e /users_home/existed_after ] || echo failed
    )
    sleep 1
done

exit 0
