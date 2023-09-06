FROM jupyter/scipy-notebook:python-3.10

LABEL org.opencontainers.image.source="https://github.com/NVSL/delegate_function" \
      org.opencontainers.image.title="cfiddle-slurm-cluster" \
      org.opencontainers.image.description="delgeate_function + Slurm Docker cluster on Ubuntu" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      maintainer="Steven Swanson"

USER root
RUN apt-get update --fix-missing
#RUN apt-get install -y software-properties-common
#RUN add-apt-repository ppa:deadsnakes/ppa
#RUN apt-get update --fix-missing
#RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata 
RUN apt-get install -y host iputils-ping sudo gosu git sudo && apt-get clean



#RUN python -m ensurepip && python -m pip install --upgrade pip
#RUN apt-get install -y python3.11 && apt-get clean
#RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1
#RUN python -m ensurepip && python -m pip install --upgrade pip



RUN mkdir /slurm
RUN mkdir /build
WORKDIR /slurm

COPY ./SLURM_TAG ./
COPY ./IMAGE_TAG ./

COPY ./slurm.conf ./
COPY ./slurmdbd.conf ./

COPY ./install_slurm.sh ./
COPY ./env.sh ./
RUN  ( . ./env.sh; env; ./install_slurm.sh  --client-only )

RUN groupadd -r cfiddle
RUN useradd -r -g cfiddle cfiddle


COPY ./cfiddle ./cfiddle
COPY ./delegate-function ./delegate-function
COPY ./hungwei-class ./hungwei-class

COPY ./install_cfiddle.sh  ./
RUN  ( . ./env.sh; ./install_cfiddle.sh )
RUN  (. ./env.sh; cd hungwei-class; pip install -e .)

#COPY . /build/cfiddle-cluster
#RUN (cd /build/cfiddle-cluster; /opt/conda/bin/pip install -e .)

# This is very kludgy.  Definitely not produciton ready
COPY test_slurm.sh ./
COPY cluster_password.txt ./
RUN cat ./cluster_password.txt >> /etc/passwd
COPY cluster_group.txt ./
RUN cat ./cluster_group.txt >> /etc/group

COPY usernode-entrypoint.sh /usr/local/bin/usernode-entrypoint.sh
COPY user-entrypoint.sh /usr/local/bin/user-entrypoint.sh 
RUN chmod a+x /usr/local/bin/user-entrypoint.sh /usr/local/bin/usernode-entrypoint.sh

#USER jovyan

HEALTHCHECK NONE

#RUN apt-get install -y openssh-server acl


RUN mkdir -p /cfiddle_scratch
RUN chmod a+rwx /cfiddle_scratch

ENTRYPOINT ["/usr/local/bin/usernode-entrypoint.sh"]
#CMD ["slurmdbd"]
CMD ["start-notebook.sh", "--NotebookApp.token='slurmify'" ]