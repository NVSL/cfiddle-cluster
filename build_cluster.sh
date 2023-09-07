# #!/usr/bin/bash

set -ex 

# ## Step 1:  Provisioning the Servers
# 
# We will assume you are setting up a cluster with one head node and two
# workers.  Adding more workers is straightforward.  If you only have
# two machines available, you can just build one worker.  If you only
# have one machine, it can serve as the head node and a worker node, but
# the slurm services might cause measurement noise in your CFiddle
# experiments.
# 
# Start off by
# 
# 1.  Provisioning the three machines with Ubuntu 22.04
# 2.  Make sure you can ssh into them.
#
# SSH into the head node and run the following commands: SSH in,
# install `git`, and checkout this repo and install docker (these
# you'll need to cut and paste)
# 
# export DEBIAN_FRONTEND=noninteractive
# apt-get update && apt-get upgrade -y
# apt-get install -y git
# git clone https://github.com/NVSL/cfiddle-cluster.git
# ./cfiddle-cluster/install_docker.sh
#
#
# From here on we'll refer to the IP address of the head node as
# `HEAD_ADDR`, and use `WORKER_ADDRS` to refer to the list of workers.
# Both of these can be set in `config.sh`.
# 
# If you get your machines from a cloud provider, they have two IP
# addresses -- An private IP address on the cloud provider's network and
# a public address that you can SSH into.  We are going to use the
# _external_ addresses for setting up the cluster. 
# 
# ## Step 2: Setting up Head Node
# 
# SSH into the head node.  Edit `config.sh` to include the IP addresses
# of your machines:
# 
# cd cfiddle-cluster
# pico config.sh
#
# Your cluster is now configured!  To bring it up and test it, just run this script:
#
# ./build_and_test.sh
#
# Read on to see what the script is doing, but all the code that follows should work as written.
#
# Set up your environment:
#
source config.sh
./check_config_sanity.sh
# 
# You'll need to do that everytime you login to maintain your cluster.
#

# ## Step 3: Create A Docker Swarm
# 
# [Docker Swarm](https://docs.docker.com/engine/swarm/) is a tool for
# orchestrating Docker containers across multiple machines.  It's going
# to do all the heavy lifting of starting and tending to the Slurm nodes.
# 
# If you aren't familiar with swarm and/or the steps below don't work
# as expected, do the [swarm
# tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/).
# 
# First, on your head node, create the swarm:
# 
docker swarm init --advertise-addr $HEAD_ADDR
SWARM_TOKEN=$(docker swarm join-token -q)
# 
# It'll respond with something like:
# 
# ```
# Swarm initialized: current node (dxn1zf6l61qsb1josjja83ngz) is now a manager.
# 
# To add a worker to this swarm, run the following command:
# 
#     docker swarm join --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c 192.168.99.100:2377
# 
# To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
# ```
# 
# Copy the `docker swarm join` command, and run it on each of the workers:
# 
for W in $WORKER_ADDRS; ssh $W "docker swarm join $HEAD_ADDR:2377"
# 
# And verify that your swarm now has three members:
# 
docker node ls
# 
# Which should give something like this:
# 
# ```
# ID                            HOSTNAME                   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
# 7ji737xit1a0wz4f5vi3adxu7 *   cfiddle-cluster-testing    Ready     Active         Leader           24.0.5
# 4v0hj6bslg4baj5fjog1vjqjp     cfiddle-cluster-worker-0   Ready     Active                          24.0.5
# gx2tvady2o4i4gi5ffd0l8bk0     cfiddle-cluster-worker-1   Ready     Active                          24.0.5
# ```
# 
# Next we need to label the nodes so we can constraint where the slurm
# services run.  These commands will do it.  Your hostnames might be
# different, but they should match the output of the `docker node ls`
# command above:
#
WORKER_NODE_IDS=$(docker node ls --format '{{.ID}} {{.ManagerStatus}}' | grep -v Leader | cut -f 1 -d ' ')
HEAD_NODE_ID=$(docker node ls --format '{{.ID}} {{.ManagerStatus}}' | grep Leader | cut -f 1 -d ' ')
docker node update --label-add slurm_role=head_node $HEAD_NODE_ID
for W in $WORKER_NODE_IDS; do docker node update --label-add slurm_role=worker $W;done
# 
# `docker-compose.yml` contains constraints that will ensure that one
# worker container runs on each worker node.
# 
# 
# ## Step 4: Create User Accounts
# 
# First, we'll create the `cfiddle` account on each worker.  It will be
# a privileged account that will be used to spawn the sandbox docker
# container on the worker nodes, so it needs to be in the `docker`
# group.
# 
for W in $WORKER_ADDRS; do ssh $W -r -s /usr/sbin/nologin -u 7000 -G docker cfiddle;done
# Second, we'll create some test users.  These are stand-ins for your
# real users.  We are going to create them locally, with their home
# directories in `/home` and then mount them via NFS into the
# containers.  As mentioned above, you'll probably want different, more
# permanent/maintainable solution to this.
#
# One nice thing about slurm is that we don't need to create these
# users on the worker nodes.  Everything is based on numeric user IDs.
# 
useradd -p test_user1 test_user1 -m 
useradd -p test_user2 test_user2 -m
useradd -p jovyan -g 100 -u 1000 jovyan -m
# 
# 
# #root@cfiddle-cluster-testing:~/cfiddle-cluster# groupadd --gid 1001 docker_users
# #-- probably not necessary?  But the group ids for the docker group don't match across docker images and the physical machines
# #root@cfiddle-cluster-testing:~/cfiddle-cluster# 
# #root@cfiddle-cluster-testing:~/cfiddle-cluster# groupadd cfiddlers -- necessary?
# 
# ## Step 6: Set up NFS
# 
# For our quick-and-dirty NFS server, we need to load the necessary modules, install a package, and populate `/etc/exports`:
# 
# ```
modprobe nfs
modprobe nfsd
apt-get install -y nfs-kernel-server
echo '/home                  *(rw,no_subtree_check) ## cfiddle_cluster' >> /etc/exports
exportfs -ra
# ```
# 
# You can test it with :
# 
# ```
mount -t nfs localhost:/home /mnt
ls /mnt/
[ ls /mnt | grep test_user1 ]
# ```
# 
# Which should yield:
# 
# ```
# test_user1  test_user2
# ```
# 
# Clean up the test mount:
# 
umount /mnt
# 
# ## Step 5: Build the Docker Image
# 
# Finally, we can build the docker images
# 
docker compose build --progress=plain
# 
# ## Step 7: Distribute The Docker Images
# 
# We need to share the images we built with the worker nodes.  The
# "right" way to do this is with a [local docker
# registery](https://docs.docker.com/registry/deploying/).  I couldn't
# get that to work, we will use [docker hub](http://dockerhub.com/)
# instead.
# 
# Create an account, and put your username in `config.sh`.
# 
# Then, login with your username:
# 
docker login -u $DOCKERHUB_USERNAME
# 
# It'll ask you for your password and let you know you've succeeded.
# 
# You can then distributed the images to the workers with:
# 
./distribute_images.sh
#
# ## Step 8: Create User Accounts
# 
# First, we'll create the `cfiddle` account on each worker.  It will be
# a privileged account that will be used to spawn the sandbox docker
# container on the worker nodes, so it needs to be in the `docker`
# group.
# 
for W in $WORKER_ADDRS; do ssh $W useradd -r -s /usr/sbin/nologin -u 7000 -G docker cfiddle;done
# Second, we'll create some test users.  These are stand-ins for your
# real users.  We are going to create them locally, with their home
# directories in `/home` and then mount them via NFS into the
# containers.  As mentioned above, you'll probably want different, more
# permanent/maintainable solution to this.
#
# One nice thing about slurm is that we don't need to create these
# users on the worker nodes.  Everything is based on numeric user IDs.
# 
useradd -p test_user1 test_user1 -m 
useradd -p test_user2 test_user2 -m
useradd -p jovyan -g 100 -u 1000 jovyan -m
#
# Then we will populate the jovyan account (which is for testing jupyter notebook) by exatract its contents from the userage and copying them into the local home directory:
docker create --name extract_jovyan cfiddle-user # create a data only container we can copy out out of
docker cp extract_jovyan:/home/jovyan /home/
chown -R jovyan /home/jovyan
docker container rm extract_jovyan  # cleanup
# 
# 
# #root@cfiddle-cluster-testing:~/cfiddle-cluster# groupadd --gid 1001 docker_users
# #-- probably not necessary?  But the group ids for the docker group don't match across docker images and the physical machines
# #root@cfiddle-cluster-testing:~/cfiddle-cluster# 
# #root@cfiddle-cluster-testing:~/cfiddle-cluster# groupadd cfiddlers -- necessary?

# 
# ## Step 9: Bring up the Cluster
# 
# To bring up the cluster, we can just do:
# 
./start_cluster.sh
# 
# which will yield:
# 
# ```
# Ignoring unsupported options: build
# 
# Creating network slurm-stack_default
# Creating service slurm-stack_c1-srv
# Creating service slurm-stack_c2-srv
# Creating service slurm-stack_mysql-srv
# Creating service slurm-stack_slurmdbd-srv
# Creating service slurm-stack_slurmctld-srv
# Creating service slurm-stack_userhost-srv
# ```
# 
# You can check that things are running with :
# 
docker service ls
# 
# Which should show:
# 
# ```
# ID             NAME                        MODE         REPLICAS   IMAGE                       PORTS
# zapsx66pxy1s   slurm-stack_c1-srv          replicated   1/1        cfiddle-cluster:latest
# rs9zndo78p33   slurm-stack_c2-srv          replicated   1/1        cfiddle-cluster:latest
# t1j5f1snf63m   slurm-stack_mysql-srv       replicated   1/1        mysql:5.7
# iaq2q7rd1t0y   slurm-stack_slurmctld-srv   replicated   1/1        cfiddle-cluster:latest
# nrjz81rjjja1   slurm-stack_slurmdbd-srv    replicated   1/1        cfiddle-cluster:latest
# 3rygur9wnlq6   slurm-stack_userhost-srv    replicated   1/1        cfiddle-cluster:latest
# ```
# 
# The `c1` and `c2` services are running on our two worker nodes to run
# Slurm jobs.  The next three are running on the head node to managed
# the cluster.
# 
# The `userhost` container is stand-in for the machines where users will
# do their work and submit jobs.
# 
# Things are running properly, if you the `REPLICAS` column contains
# `1/1` on each line.  If one of them has `0/1`, you can check the
# status of that service with (e.g., for `slurm-stack_slurmctld-srv`):
# 
# docker service ps --no-trunc slurm-stack_slurmctld-srv
# 
# and dive deeper with
# 
# docker service logs slurm-stack_slurmctld-srv
# 
# ## Step 10:  Test The Slurm Cluster
# 
# Now we can test the operation of the Slurm cluster.  To do that we'll
# start a shell in user node container, but first we need its name:
# 
# ```
docker container ls
# ```
# Yielding:
# ```
# CONTAINER ID   IMAGE                       COMMAND                  CREATED         STATUS         PORTS                 NAMES
# 9753ad8fc5de   cfiddle-cluster:latest      "/usr/local/bin/dock…"   7 minutes ago   Up 7 minutes                         slurm-stack_userhost-srv.1.pfzqidlnq7ow74y8eys3tr5vs
# 948cf848d285   cfiddle-cluster:latest      "/usr/local/bin/dock…"   7 minutes ago   Up 7 minutes                         slurm-stack_slurmctld-srv.1.hwkx0uibtsohblfxyl5zcybz7
# dd8e12974325   cfiddle-cluster:latest      "/usr/local/bin/dock…"   7 minutes ago   Up 7 minutes                         slurm-stack_slurmdbd-srv.1.yz65lbuqf2pmme2ovj2sges8s
# f7b4042bea25   mysql:5.7                   "docker-entrypoint.s…"   7 minutes ago   Up 7 minutes   3306/tcp, 33060/tcp   slurm-stack_mysql-srv.1.4sa09y0co9mwnq1ismae1kgfg
# ```
# 
# Your container names will be different but you want the one with `userhost` in it.
#
# config.sh extracts these sevice names and stores them in some environment variables, so we source it again
. config.sh
echo $userhost
echo $slurmctld
echo $slurmdbd
echo $mysql
# 
# Then you can check that the cluster is running by executing `sinfo` in the userhost container:
# 
docker exec -it $userhost sinfo
#
# It should provide information about your cluster:
# 
# ```
# PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
# normal*      up   infinite      2   idle c[1-2]
# ```
#
# Then we can submit a job:
docker exec -it $userhost salloc srun bash -c 'echo -ne "hello from "; hostname'
# and that's it!
exit 0
