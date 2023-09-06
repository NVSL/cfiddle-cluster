#!/usr/bin/bash

set -ex

for IMAGE_NAME in cfiddle-cluster:latest cfiddle-user:latest cfiddle-sandbox:latest; do 
    docker tag $IMAGE_NAME $DOCKERHUB_USERNAME/$IMAGE_NAME
    docker push $DOCKERHUB_USERNAME/$IMAGE_NAME
    ssh root@$WORKER_0_ADDR docker pull $DOCKERHUB_USERNAME/$IMAGE_NAME
    ssh root@$WORKER_1_ADDR docker pull $DOCKERHUB_USERNAME/$IMAGE_NAME
    ssh $WORKER_0_ADDR  docker image tag $DOCKERHUB_USERNAME/$IMAGE_NAME $IMAGE_NAME
    ssh $WORKER_1_ADDR  docker image tag $DOCKERHUB_USERNAME/$IMAGE_NAME $IMAGE_NAME
done

