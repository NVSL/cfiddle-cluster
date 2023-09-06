FROM ubuntu:jammy
#jupyter/scipy-notebook:python-3.10

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

COPY ./config.sh ./
COPY ./install_python.sh ./
RUN ( . ./config.sh; env; ./install_python.sh)

COPY ./cfiddle ./cfiddle
COPY ./delegate-function ./delegate-function
COPY ./install_cfiddle.sh  ./
RUN  ( . ./config.sh; ./install_cfiddle.sh )

RUN mkdir -p /cfiddle_scratch
RUN chmod a+rwx /cfiddle_scratch

ENTRYPOINT ["/usr/bin/env"]
