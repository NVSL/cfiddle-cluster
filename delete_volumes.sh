#!/usr/bin/bash

set -ex

docker volume rm $(docker volume ls | grep slurm-stack | cut -f 6 -d ' ') || true
for WORKER in $WORKER_ADDRS; do 
    ssh $WORKER docker volume rm $(ssh $WORKER docker volume ls | grep slurm-stack | cut -f 6 -d " ")
done
