#!/usr/bin/bash

set -ex

docker volume rm $(docker volume ls | grep slurm-stack | cut -f 6 -d ' ') || true
ssh $WORKER_0_ADDR docker volume rm $(ssh $WORKER_0_ADDR docker volume ls | grep slurm-stack | cut -f 6 -d " ")
ssh $WORKER_1_ADDR docker volume rm $(ssh $WORKER_1_ADDR docker volume ls | grep slurm-stack | cut -f 6 -d " ")

