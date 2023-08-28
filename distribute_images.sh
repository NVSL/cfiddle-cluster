#!/usr/bin/bash

set -ex

docker tag cfiddle-cluster:$IMAGE_TAG $DOCKERHUB_USERNAME/cfiddle-cluster:$IMAGE_TAG
docker push $DOCKERHUB_USERNAME/cfiddle-cluster:$IMAGE_TAG
ssh root@$WORKER_0_ADDR docker pull $DOCKERHUB_USERNAME/cfiddle-cluster:$IMAGE_TAG
ssh root@$WORKER_1_ADDR docker pull $DOCKERHUB_USERNAME/cfiddle-cluster:$IMAGE_TAG
ssh $WORKER_0_ADDR  docker image tag $DOCKERHUB_USERNAME/cfiddle-cluster:$IMAGE_TAG cfiddle-cluster:$IMAGE_TAG
ssh $WORKER_1_ADDR  docker image tag $DOCKERHUB_USERNAME/cfiddle-cluster:$IMAGE_TAG cfiddle-cluster:$IMAGE_TAG

