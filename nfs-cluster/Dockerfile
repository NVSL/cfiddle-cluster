FROM jupyter/scipy-notebook

USER root
RUN apt-get update -y && apt-get install -y nfs-common
RUN mkdir /nfs-test
RUN mkdir /users_home
WORKDIR /nfs-test
COPY ./test_script.sh ./
RUN chmod u+x test_script.sh
COPY ./fstab /etc/fstab


#ENTRYPOINT [ "/usr/bin/bash", "-c" ]
ENTRYPOINT ["/nfs-test/test_script.sh"]
