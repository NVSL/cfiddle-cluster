# A Containerized CFiddle Cluster Deployment

This repo describes/embodies how to deploy a cluster of machines for
use with CFiddle so that multiple users (e.g., students) can share
access to the machines while ensuring that their cfiddle experiments
run alone on the machine so their measurements are accurate.  It also
ensures that the users can't mess up the machines or interfere with
eachother's jobs.

The approach it takes it to use the [Slurm job
scheduler](https://slurm.schedmd.com/documentation.html) to schedule
the execution of the cfiddle experiments.  It makes extensive use of
Docker containers and Docker's Swarm and Stack facilities.

There are many other ways to accomplish the same goal.  The approach
here is meant to be simplest, although it is not the most elegant.  It
is the one the author is currently using in production.

The last section of the document describes other configurations that
might be desirable in your situation.

## What This Repo Builds

The instructions and code in this repo will let you assemble the following:

1.  A group of _worker nodes_ to run cfiddle jobs
2.  A _head node_ to coordinate access to the cluster.
3.  An appropriate configuration for cfiddle so it'll run jobs on the cluster.
4.  A exampler _user node_ that is not part of the slurm cluster but serves Jupyter Notebooks that can submit cfiddle jobs to the cluster.
5.  Three docker images:
    * One for the head node and worker nodes
    * One for the user node
    * A sandbox docker image to run the user's code.
6.  A couple test user accounts to show that everything works.

We will assume that the cluster is dedicated to running CFiddle jobs
and nothing else.

### Theory of Operation

We will configure CFiddle so that when the user's CFiddle code
(running on the "user node") requests execution of an experiment,
CFiddle will use the facilities provided by `delegate_function` to run
the code someplace other than the local machine.

That "someplace" will be one in single-use "sandbox" docker container
running on one of the worker nodes in our Slurm cluster.
`delegate_function` will accomplish this by submitting a Slurm job to
the cluster and spawning the sandbox container.

The user node and the worker nodes will all share a single `/home/`
directory so the users files are available to their job running on the
slurm cluster.

Slurm will schedule the job to a proxy container, and the job will
spawn a sandbox container execute the code, collect the outputs, and
return them to the user node.

How, exactly, `delegate_function` bundles up the CFiddle code and its
inputs and then collects its outputs is outside the scope of this
document.

### What We Provide and What You Need to Provide

The implementation embodied in this git repo is meant to make it easy
as possible to set up a CFiddle cluster, so most the implementation
this document describes is suitable for use in deployment (although
you need to customize some configurations files).

However, there are two aspects of the system that 'fakes' because the
real-life implementations are varied, potentially complex, and not
Cfiddle- or Slurm-related.  These are:

1. Shared user directories
2. Synchronized user accounts

In order to use this system in deployment, you'll need to solve both
these problems.  You can use solutions I've used here a starting
point, but they will likely need some tweaking.

For shared user directories, the instruction below set up a simple NFS
server, which will work fine for simple, stand-alone installations.

The solution for synchronized user accounts is much messier and less
scalable, but you could make it work in a pinch.

### Implementation Roadmap

This deployment is fully containerized so that we don't have to
install anything other than `git` (to clone this repo) and `docker` on
machines to get things working.

We will build this system in layers.

First, we will acquire a head node and set of worker nodes and install docker on them.

Second, we will create a docker swarm from those nodes to facilitate their management.

Third, we will instantiate a set of docker "services" using docker
"stacks".  This will start several containers on the head node to run
Slurm and a container on each worker node.

## What this Repo Does not Build

This repo is not a great resource for deploying a general purpose
Slurm cluster.

It is also not instructions for using an existing Slurm cluster to run
Cfiddle jobs.  This certainly possible and the tools support it.  If
you have a suitable Slurm cluster available, it's probably easier to
go that route.

## But I Want to Do Something Slightly Different

That's great!  This repo probably provides helpful hints.

Also, the maintainers are excited to help people use CFiddle, so
please email sjswanson@ucsd.edu if you have questions or need help.

##  What You Will Need

### Hardware

You will need at least two machines: One worker node and one head node.

The head node can pretty much any server (or virtual machine) that
runs a recent version of Docker.  You'll need administrative access to
it.

The worker machine is where the CFiddle experiments will run.  It
should be dedicated to this task and not be running anything else.

For testing this guide, we used bare metal cloud servers from
https://deploy.equinix.com/.  Any x86 instance type will do for
testing.  Pick something cheap.

You need to be familiar with how provision servers, install the OS,
and be able to ssh into them.

### Software

We built this guide with the following software:

1. Ubuntu 22.04
2. Docker version 24.0.5
3. The latest version of `CFiddle`
4. The latest version of `delegate_function`

In principle, the version of Linux shouldn't matter much, but some of
the scripts will probably need to be adjusted.

We are using some moderately new docker features.  In particular, we
need docker-compose.yml 3.8, so you'll need at least Docker 19.03.

## Step 1:  Provisioning the Servers

We will assume you are setting up a cluster with one head node and two
workers.  Adding more workers is straightforward.  If you only have
two machines available, you can just build one worker.  If you only
have one machine, it can serve as the head node and a worker node, but
the slurm services might cause measurement noise in your CFiddle
experiments.

Start off by

1.  Provisioning the three machines with Ubuntu 22.04
2.  Make sure you can ssh into them.

SSH in, install `git`, and  checkout this repo:

```
apt-get update
apt-get install -y git
git clone https://github.com/NVSL/cfiddle-cluster.git
```

Then install docker:

```
./cfiddle-cluster/install_docker.sh
```

From here on we'll refer to the IP address of the head node as `HEAD_ADDR`, and the addresses of the workers as `WORKER_0_ADDR` and `WORKER_1_ADDR`.

If you get your machines from a cloud provider, they have two IP
addresses -- An private IP address on the cloud provider's network
and a public address that you can SSH into.  We are going to use
the _internal_ addresses for setting up the cluster.


## Step 2: Setting up Head Node

SSH into the head node.  Edit `env.sh` to include the IP addresses of your machines:

```
cd cfiddle-cluster
pico env.sh
```

Then source `env.sh`, to set the environment variables we need:

```
source env.sh
```

You'll need to do that everytime you login.

## Step 3: Create A Docker Swarm

[Docker Swarm](https://docs.docker.com/engine/swarm/) is a tool for
orchestrating Docker containers across multiple machines.  It's going
to do all the heavy lifting of starting and tending to the Slurm nodes.

If you aren't familiar with swarm and/or the steps below don't work as expected, do the [swarm tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/).

First, on your head node, create the swarm:

```
docker swarm init --advertise-addr $HEAD_ADDR
```

It'll respond with something like:

```
Swarm initialized: current node (dxn1zf6l61qsb1josjja83ngz) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c 192.168.99.100:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

Copy the `docker swarm join` command, and run it on each of the workers:

```
ssh $WORKER_0_ADDR 'docker swarm join <...copied command...>'
ssh $WORKER_1_ADDR 'docker swarm join <...copied command...>'
```

And verify that your swarm now has three members:

```
docker node ls
```

Which should give something like this:

```
ID                            HOSTNAME                   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
7ji737xit1a0wz4f5vi3adxu7 *   cfiddle-cluster-testing    Ready     Active         Leader           24.0.5
4v0hj6bslg4baj5fjog1vjqjp     cfiddle-cluster-worker-0   Ready     Active                          24.0.5
gx2tvady2o4i4gi5ffd0l8bk0     cfiddle-cluster-worker-1   Ready     Active                          24.0.5
```

Next we need to label the nodes so we can constraint where the slurm
services run.  These commands will do it.  Your hostnames might be
different, but they should match the output of the `docker node ls`
command above:

```
docker node update --label-add slurm_role=head_node cfiddle-cluster-testing
docker node update --label-add slurm_role=worker cfiddle-cluster-worker-0
docker node update --label-add slurm_role=worker cfiddle-cluster-worker-1
```

`docker-compose.yml` contains constraints that will ensure that one
worker container runs on each worker node.


## Step 4: Create User Accounts

First, we'll create the `cfiddle` account on each worker.  It will be
a privileged account that will be used to spawn the sandbox docker
container on the worker nodes, so it needs to be in the `docker`
group.

```
ssh $WORKER_0_ADDR useradd -r -s /usr/sbin/nologin -u 7000 -G docker cfiddle
ssh $WORKER_1_ADDR useradd -r -s /usr/sbin/nologin -u 7000 -G docker cfiddle
```

Second, we'll create some test users.  These are stand-ins for your
real users.  We are going to create them locally, with their home
directories in `/home` and then mount them via NFS into the
containers.  As mentioned above, you'll probably want different, more
permanent/maintainable solution to this.

```
useradd -p test_user1 test_user1 -m 
useradd -p test_user2 test_user2 -m
```

Now, for a bug kludge: We need to get these users into docker images
so they are available on the worker nodes:

```
grep 'cfiddle\|test_' /etc/passwd > cluster_password.txt
grep 'cfiddle\|test_' /etc/group > cluster_group.txt
```

#root@cfiddle-cluster-testing:~/cfiddle-cluster# groupadd --gid 1001 docker_users

#-- probably not necessary?  But the group ids for the docker group don't match across docker images and the physical machines

#root@cfiddle-cluster-testing:~/cfiddle-cluster# 


#root@cfiddle-cluster-testing:~/cfiddle-cluster# groupadd cfiddlers -- necessary?

## Step 6: Set up NFS

For our quick-and-dirty NFS server, we need to:

Load the necessary modules, install a package and populate `/etc/exports`:

```
modprobe nfs
modprobe nfsd
apt-get install -y nfs-kernel-server
echo '/home                  *(rw,no_subtree_check)' >> /etc/exports
```

You can test it with :

```
mount -t nfs localhost:/users_home /mnt
ls /mnt/
```

Which should yield:

```
test_user1  test_user2
```

Clean up the test mount:

```
umount /mnt
```

## Step 5: Build the Docker Image

Finally, we can build the docker images

```
docker compose build --progress=plain
```


## Step 7: Distribute The Docker Images

We need to share the images we built with the worker nodes.  The
"right" way to do this is with a [local docker
registery](https://docs.docker.com/registry/deploying/).  I couldn't
get that to work, we will use [docker hub](http://dockerhub.com/)
instead.

Create an account, and put your username in `env.sh`.

Then, login with your username:

```
docker login -u $DOCKERHUB_USERNAME
```

It'll ask you for your password and let you know you've succeeded.

You can then distributed the images to the workers with:

```
./distribute_images.sh
```

## Step 8: Bring up the Cluster

To bring up the cluster, we can just do:

```
docker stack deploy -c docker-compose.yml slurm-stack
```

which will yield:

```
Ignoring unsupported options: build

Creating network slurm-stack_default
Creating service slurm-stack_c1-srv
Creating service slurm-stack_c2-srv
Creating service slurm-stack_mysql-srv
Creating service slurm-stack_slurmdbd-srv
Creating service slurm-stack_slurmctld-srv
Creating service slurm-stack_userhost-srv
```

You can check that things are running with :

```
docker service ls
```

Which should show:

```
ID             NAME                        MODE         REPLICAS   IMAGE                       PORTS
zapsx66pxy1s   slurm-stack_c1-srv          replicated   1/1        cfiddle-cluster:21.08.6.1
rs9zndo78p33   slurm-stack_c2-srv          replicated   1/1        cfiddle-cluster:21.08.6.1
t1j5f1snf63m   slurm-stack_mysql-srv       replicated   1/1        mysql:5.7
iaq2q7rd1t0y   slurm-stack_slurmctld-srv   replicated   1/1        cfiddle-cluster:21.08.6.1
nrjz81rjjja1   slurm-stack_slurmdbd-srv    replicated   1/1        cfiddle-cluster:21.08.6.1
3rygur9wnlq6   slurm-stack_userhost-srv    replicated   1/1        cfiddle-cluster:21.08.6.1
```

The `c1` and `c2` services are running on our two worker nodes to run
Slurm jobs.  The next three are running on the head node to managed
the cluster.

The `userhost` container is stand-in for the machines where users will
do their work and submit jobs.

Things are running properly, if you the `REPLICAS` column contains
`1/1` on each line.  If one of them has `0/1`, you can check the
status of that service with (e.g., for `slurm-stack_slurmctld-srv`):

```
docker service ps --no-trunc slurm-stack_slurmctld-srv
```

and dive deeper with

```
docker service logs slurm-stack_slurmctld-srv
```

Step 9:  Test The Slurm Cluster

Now we can test the operation of the Slurm cluster.  To do that we'll
start a shell in user node container, but first we need its name:

```
docker container ls
```
Yielding:
```
CONTAINER ID   IMAGE                       COMMAND                  CREATED         STATUS         PORTS                 NAMES
9753ad8fc5de   cfiddle-cluster:21.08.6.1   "/usr/local/bin/dock…"   7 minutes ago   Up 7 minutes                         slurm-stack_userhost-srv.1.pfzqidlnq7ow74y8eys3tr5vs
948cf848d285   cfiddle-cluster:21.08.6.1   "/usr/local/bin/dock…"   7 minutes ago   Up 7 minutes                         slurm-stack_slurmctld-srv.1.hwkx0uibtsohblfxyl5zcybz7
dd8e12974325   cfiddle-cluster:21.08.6.1   "/usr/local/bin/dock…"   7 minutes ago   Up 7 minutes                         slurm-stack_slurmdbd-srv.1.yz65lbuqf2pmme2ovj2sges8s
f7b4042bea25   mysql:5.7                   "docker-entrypoint.s…"   7 minutes ago   Up 7 minutes   3306/tcp, 33060/tcp   slurm-stack_mysql-srv.1.4sa09y0co9mwnq1ismae1kgfg
```

Your container names will be different but you want the one with `userhost` in it.

Then you can do:

```
docker exec -it slurm-stack_userhost-srv.1.pfzqidlnq7ow74y8eys3tr5vs bash
```

Which will give you a shell in the user node container, where you can do:

```
sinfo
```
to see information about your cluster:

```
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up   infinite      2   idle c[1-2]
```

and then you can run some jobs with:

```
./test_slurm.sh
```

Which will show you a live-updating view of the job queue.  When it's
empty (or you get board), Control-C to quit, and then `exit` to get
out of the user node container.






## Alternative Configurations

The system we just built has some draw backs:

1. The proxy container mechanism means that the Slurm cluster is not suitable for general use.
2. All the CFiddle jobs run as the same user -- `cfiddle`.

These decisions are both driven by the desire for simplicity.  In
particular, proxy containers avoid the need maintain user accounts or
directories across the worker nodes.

A more elegant installation, would keep user accounts synchronized
across the head node and the workers, provide unified home directories
across the machines, and then use the worker nodes themselves be
members of the Slurm cluster.

## Setting up NFS

On server:
modprobe nfs
modprobe nfsd
apt-get install -y nfs-kernel-server
cat >> /etc/exports
/users_home                  *(rw,no_subtree_check)
mount -t nfs localhost:/users_home /mnt
! [ -e /mnt/foo ]
touch /users_home/foo
[ -e /mnt/foo ]

On workers?

## Possibly useful

https://github.com/nateGeorge/slurm_gpu_ubuntu

## Munge Key

It's created in the docker image we use.  This may not be a good choice.  You could mount it over NFS.
