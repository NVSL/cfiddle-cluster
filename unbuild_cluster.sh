#!/usr/bin/bash

# The goal of this script is to clean up enough so that `build_cluster.sh` will run correctly.
# 
# Note it does some general tidying of docker as well, so if you are
# using this machine for anything else, you should check to make sure
# it doesn't do something you don't want.

# First stop the cluster:

./stop_cluster.sh

# Remove users

userdel -rf test_user1
userdel -rf test_user2
userdel -rf jovyan 

for W in $WORKER_ADDRS; do ssh $W userdel -f cfiddle;done

# Remove stopped containers

docker container prune
for W in $WORKER_ADDRS; do ssh $W docker container prune;done

docker image prune
for W in $WORKER_ADDRS; do ssh $W docker image prune;done

# delete volumes

./delete_volumes.sh
docker volume prune

# cleanup nfs exports and stop nfs.

cp /etc/exports /etc/exports.bak
grep -v cfiddle_cluster < /etc/exports.bak > /etc/exports
exportfs -ra

# Remove munge key
rm -rf /etc/munge

# delete cfiddle and delegate_function

rm -rf cfiddle delegate_function

# Tear down swarm

for W in $WORKER_ADDRS; do ssh $W docker swarm leave -f;done
docker swarm leave -f


