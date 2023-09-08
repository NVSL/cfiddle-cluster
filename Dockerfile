FROM ubuntu:jammy

LABEL org.opencontainers.image.source="https://github.com/NVSL/delegate_function" \
      org.opencontainers.image.title="cfiddle-cluster" \
      org.opencontainers.image.description="Slurm Docker cluster on Ubuntu" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      maintainer="Steven Swanson"

USER root

RUN mkdir /slurm
WORKDIR /slurm

RUN apt-get update --fix-missing
RUN apt-get install -y host iputils-ping sudo gosu git  && apt-get clean

COPY ./config.sh ./

COPY ./install_python.sh ./
RUN ( . ./config.sh; env; ./install_python.sh)


COPY ./slurm.conf ./
COPY ./slurmdbd.conf ./
COPY ./cfiddle ./cfiddle
COPY ./delegate-function ./delegate-function

COPY ./install_cfiddle.sh  ./
RUN  ( . ./config.sh; ./install_cfiddle.sh )


COPY ./install_slurm.sh ./
RUN  ( . ./config.sh; ./install_slurm.sh)

COPY ./install_docker.sh ./
RUN (. ./config.sh; ./install_docker.sh)

COPY ./create_jovyan.sh ./
RUN (. ./config.sh; ./create_jovyan.sh)

RUN useradd -r -s /usr/sbin/nologin -u 7000 -G docker -p fiddle cfiddle

COPY ./cfiddle_sudoers /etc/sudoers.d/

HEALTHCHECK NONE

#RUN apt-get install -y openssh-server acl

COPY slurm-entrypoint.sh /usr/local/bin/slurm-entrypoint.sh
RUN chmod a+x /usr/local/bin/slurm-entrypoint.sh

RUN mkdir -p /cfiddle_scratch
RUN chmod a+rwx /cfiddle_scratch

ENTRYPOINT ["/usr/local/bin/slurm-entrypoint.sh"]
CMD ["slurmdbd"]
