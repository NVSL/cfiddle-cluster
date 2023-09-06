FROM jupyter/scipy-notebook:python-3.10

LABEL org.opencontainers.image.source="https://github.com/NVSL/cfiddle-cluster" \
      org.opencontainers.image.title="cfiddle-slurm-cluster-sandbox" \
      org.opencontainers.image.description="Example sandbox image to communicate with a slurm cluster for running cfiddle experiments" \
      maintainer="Steven Swanson <swanson@cs.ucsd.edu>"

USER root
RUN apt-get update --fix-missing
RUN apt-get install -y host iputils-ping sudo gosu git sudo && apt-get clean

RUN mkdir /slurm
RUN mkdir /build
WORKDIR /slurm


#COPY ./slurm.conf ./
#COPY ./slurmdbd.conf ./

#COPY ./install_slurm.sh ./
#COPY ./config.sh ./
#RUN  ( . ./config.sh; env; ./install_slurm.sh  --client-only )

#RUN groupadd -r cfiddle
#RUN useradd -r -g cfiddle cfiddle

COPY ./cfiddle ./cfiddle
COPY ./delegate-function ./delegate-function
COPY ./install_cfiddle.sh  ./
RUN  ( . ./config.sh; ./install_cfiddle.sh )

# This is very kludgy.  Definitely not produciton ready
#COPY test_slurm.sh ./
#COPY cluster_password.txt ./
#RUN cat ./cluster_password.txt >> /etc/passwd
#COPY cluster_group.txt ./
#RUN cat ./cluster_group.txt >> /etc/group

RUN mkdir -p /cfiddle_scratch
RUN chmod a+rwx /cfiddle_scratch

ENTRYPOINT ["/usr/bin/env"]
