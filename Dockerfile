FROM ubuntu:jammy
#FROM jupyter/scipy-notebook

LABEL org.opencontainers.image.source="https://github.com/NVSL/delegate_function" \
      org.opencontainers.image.title="cfiddle-cluster" \
      org.opencontainers.image.description="Slurm Docker cluster on Ubuntu" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      maintainer="Steven Swanson"

USER root
RUN apt-get update
RUN apt-get install -y host iputils-ping sudo gosu

RUN mkdir /slurm
RUN mkdir /build
WORKDIR /slurm

COPY ./SLURM_TAG ./
COPY ./IMAGE_TAG ./

COPY ./slurm.conf ./
COPY ./slurmdbd.conf ./

COPY ./install_slurm.sh ./
RUN  ./install_slurm.sh

#COPY . /build/delegate-function   
#RUN (cd /build/delegate-function; /opt/conda/bin/pip install -e .)
#RUN ls /opt/conda/lib/python3.10/site-packages/cfiddle*
#COPY ./install_cfiddle.sh ./
#RUN ./install_cfiddle.sh 

#RUN groupadd cfiddlers
#RUN groupadd --gid 1001 docker_users
#RUN useradd -r -s /usr/sbin/nologin -u 7000 -G docker_users -p fiddle cfiddle


# This is very kludgy.  Definitely not produciton ready
COPY test_slurm.sh ./
COPY cluster_password.txt ./
RUN cat ./cluster_password.txt >> /etc/passwd
COPY cluster_group.txt ./
RUN cat ./cluster_group.txt >> /etc/group


#COPY ./cfiddle_sudoers /etc/sudoers.d

HEALTHCHECK NONE

#RUN apt-get install -y openssh-server acl

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

#RUN mkdir -p /cfiddle_scratch
#RUN chmod a+rwx /cfiddle_scratch

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["slurmdbd"]
