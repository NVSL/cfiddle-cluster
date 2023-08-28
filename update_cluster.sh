#!/usr/bin/bash

set -ex

docker compose build --progress=plain

./distribute_images.sh

docker stack rm slurm-stack

docker stack deploy -c docker-compose.yml slurm-stack || true
docker stack deploy -c docker-compose.yml slurm-stack || true

docker service ls
docker container ls
