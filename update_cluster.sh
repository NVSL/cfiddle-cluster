#!/usr/bin/bash

set -ex

#grep 'cfiddle\|test_\|jovyan' /etc/passwd > cluster_password.txt
#grep 'cfiddle\|test_\|jovyan' /etc/group > cluster_group.txt


docker compose --progress=plain  build

./distribute_images.sh

./stop_cluster.sh
./start_cluster.sh

sleep 1
docker service ls
docker container ls
