#!/usr/bin/bash

set -ex

docker stack deploy -c docker-compose.yml slurm-stack

