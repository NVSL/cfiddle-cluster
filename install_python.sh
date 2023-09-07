#!/usr/bin/bash

set -ex

apt-get update --fix-missing
apt-get install -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa
apt-get update --fix-missing
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata 
apt-get install -y python3.10 && apt-get clean
update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
