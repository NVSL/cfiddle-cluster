#!/usr/bin/bash

set -ex

docker stack rm slurm-stack;
while docker network ls | grep -q slurm-stack; do sleep 1;done;
