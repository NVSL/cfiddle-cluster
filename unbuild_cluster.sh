#!/usr/bin/bash

# The goal of this script is to clean up enough so that `build_cluster.sh` will run correctly.
# 
# Note it does some general tidying as well, so if you are using this
# machine for anything else, you should check to make sure it doesn't
# do something you don't want.

# First stop the cluster:

./stop_cluster.sh

# Remove users

userdel -f test_user1
userdel -f test_user2
userdel -f jovyan 

for W in $WORKER_ADDRS; do ssh $W userdel -f cfiddle;done

# Remove stopped containers

docker container prune
for W in $WORKER_ADDRS; do ssh $W docker container prune;done

docker image prune
for W in $WORKER_ADDRS; do ssh $W docker image prune;done

# delete volumes

./delete_volume.sh
docker volumes prune

# cleanup nfs exports and stop nfs.

cp /etc/exports /etc/exports.bak
grep -v cfiddle_cluster < /etc/exports.bak > /etc/exports
service nfs stop

# Tear down swarm

for W in $WORKER_ADDRS; do ssh $W docker swarm leave -f;done
docker swarm leave -f


