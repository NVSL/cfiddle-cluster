#!/usr/bin/bash

set -ex

docker volume rm $(docker volume ls | grep slurm-stack | cut -f 6 -d ' ') || true
for WORKER in $WORKER_ADDRS; do
    volumes=$(ssh $WORKER docker volume ls | grep slurm-stack | cut -f 6 -d " ")
    if [ "$volumes." != "." ]; then
       ssh $WORKER docker volume rm $volumes
    fi
done
