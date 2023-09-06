FROM ubuntu:jammy

LABEL org.opencontainers.image.source="https://github.com/NVSL/delegate_function" \
      org.opencontainers.image.title="cfiddle-cluster" \
      org.opencontainers.image.description="Slurm Docker cluster on Ubuntu" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      maintainer="Steven Swanson"

USER root

RUN apt-get update --fix-missing
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update --fix-missing
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata 
RUN apt-get install -y host iputils-ping sudo gosu git  && apt-get clean
#RUN python3 -m ensurepip && python3 -m pip install --upgrade pip
RUN apt-get install -y python3.10 && apt-get clean
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
#RUN python -m ensurepip && python -m pip install --upgrade pipig


RUN mkdir /slurm
RUN mkdir /build
WORKDIR /slurm

COPY ./slurm.conf ./
COPY ./slurmdbd.conf ./
COPY ./cfiddle ./cfiddle
COPY ./delegate-function ./delegate-function

COPY ./install_cfiddle.sh  ./
COPY ./config.sh ./
RUN  ( . ./config.sh; ./install_cfiddle.sh )
#RUN  (. ./config.sh; cd hungwei-class; pip install -e .)


#RUN groupadd cfiddlers
#RUN groupadd --gid 1001 docker_users
#RUN useradd -r -s /usr/sbin/nologin -u 7000 -G docker_users -p fiddle cfiddle

COPY ./install_slurm.sh ./
RUN  ( . ./config.sh; ./install_slurm.sh)

# This is very kludgy.  Definitely not produciton ready
COPY test_slurm.sh ./
COPY cluster_password.txt ./
RUN cat ./cluster_password.txt >> /etc/passwd
COPY cluster_group.txt ./
RUN cat ./cluster_group.txt >> /etc/group

#COPY ./cfiddle_sudoers /etc/sudoers.d

COPY ./install_docker.sh ./
RUN (. ./config.sh; ./install_docker.sh --client-only)

HEALTHCHECK NONE

#RUN apt-get install -y openssh-server acl

COPY slurm-entrypoint.sh /usr/local/bin/slurm-entrypoint.sh
RUN chmod a+x /usr/local/bin/slurm-entrypoint.sh

RUN mkdir -p /cfiddle_scratch
RUN chmod a+rwx /cfiddle_scratch

ENTRYPOINT ["/usr/local/bin/slurm-entrypoint.sh"]
CMD ["slurmdbd"]
