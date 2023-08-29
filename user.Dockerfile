FROM jupyter/scipy-notebook

LABEL org.opencontainers.image.source="https://github.com/NVSL/delegate_function" \
      org.opencontainers.image.title="cfiddle-slurm-cluster" \
      org.opencontainers.image.description="delgeate_function + Slurm Docker cluster on Ubuntu" \
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
COPY ./env.sh ./
RUN  ( . ./env.sh; env; ./install_slurm.sh --client-only )

COPY . /build/cfiddle-cluster
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

USER jovyan

HEALTHCHECK NONE

#RUN apt-get install -y openssh-server acl


#RUN mkdir -p /cfiddle_scratch
#RUN chmod a+rwx /cfiddle_scratch

ENTRYPOINT ["/usr/local/bin/usernode-entrypoint.sh"]
#CMD ["slurmdbd"]
CMD ["start-notebook.sh", "--NotebookApp.token='slurmify'" ]