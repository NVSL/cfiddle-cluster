#!/usr/bin/bash

# copied from here:  https://docs.docker.com/engine/install/ubuntu/
if ! [ -z ${1+x} ] && [ $1 = "--client-only" ]; then
CLIENT_ONLY=$1
else
CLIENT_ONLY="no"
fi

apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
     tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

if [ $CLIENT_ONLY = "no" ]; then
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    apt-get install -y docker-ce-cli docker-ce # we only iclude
					       # docker-ce so it'll
					       # create the docker
					       # group in a way
					       # consistent with the
					       # other images.  A
					       # better solution would
					       # probably be to create
					       # the docker group
					       # ourselves.
fi
    

