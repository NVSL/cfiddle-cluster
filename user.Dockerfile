FROM jupyter/scipy-notebook:python-3.10

LABEL org.opencontainers.image.source="https://github.com/NVSL/cfiddle-cluster" \
      org.opencontainers.image.title="cfiddle-slurm-cluster-usernode" \
      org.opencontainers.image.description="Example user image to communicate with a slurm cluster for running cfiddle experiments" \
      maintainer="Steven Swanson <swanson@cs.ucsd.edu>"

USER root
RUN apt-get update --fix-missing
RUN apt-get install -y host iputils-ping sudo gosu git sudo && apt-get clean

RUN mkdir /slurm
WORKDIR /slurm

COPY ./config.sh ./

COPY ./slurm.conf ./

COPY ./install_slurm.sh ./
RUN  ( . ./config.sh; env; ./install_slurm.sh  --client-only )

RUN groupadd -r cfiddle
RUN useradd -r -g cfiddle cfiddle

COPY ./cfiddle ./cfiddle
COPY ./delegate-function ./delegate-function

COPY ./install_cfiddle.sh  ./
RUN  ( . ./config.sh; ./install_cfiddle.sh )

COPY usernode-entrypoint.sh /usr/local/bin/usernode-entrypoint.sh
COPY user-entrypoint.sh /usr/local/bin/user-entrypoint.sh 
RUN chmod a+x /usr/local/bin/user-entrypoint.sh /usr/local/bin/usernode-entrypoint.sh

HEALTHCHECK NONE

RUN mkdir -p /cfiddle_scratch
RUN chmod a+rwx /cfiddle_scratch

ENTRYPOINT ["/usr/local/bin/usernode-entrypoint.sh"]
CMD ["start-notebook.sh", "--NotebookApp.token='slurmify'" ]