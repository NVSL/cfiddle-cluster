#!/usr/bin/bash

set -ex

for IMAGE_NAME in cfiddle-cluster:latest cfiddle-user:latest cfiddle-sandbox:latest; do 
    docker tag $IMAGE_NAME $DOCKERHUB_USERNAME/$IMAGE_NAME
    docker push $DOCKERHUB_USERNAME/$IMAGE_NAME
    for WORKER in $WORKER_ADDRS; do 
	ssh root@$WORKER docker pull $DOCKERHUB_USERNAME/$IMAGE_NAME
	ssh $WORKER  docker image tag $DOCKERHUB_USERNAME/$IMAGE_NAME $IMAGE_NAME
    done
done

