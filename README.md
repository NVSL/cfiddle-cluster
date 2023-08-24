# A Containerized CFiddle Cluster Deployment

This repo describes/embodies how to deploy a cluster of machines for use
with CFiddle so that multiple users (e.g., students) can share access
to the machines while ensuring that their cfiddle experiments run
alone on the machine so their measurements are accurate.

The approach it takes it to use the Slurm job scheduler to schedule
the execution of the cfiddle experiments.  It makes extensive use of
Docker containers and Docker's Swarm and Stack facilities.

There are many other ways to accomplish the same goal.

## What This Repo Builds

The instructions and code in this repo will let you assemble the following.:

1.  A group of worker nodes to run cfiddle jobs
2.  A head node to coordinate access to the cluster.

An appropriate configuration for cfiddle so it'll run jobs on the cluster.

We will assume that the cluster is dedicated to running CFiddle jobs
and nothing else.

## What this Repo Does not Build

This repo is not a great resource for deploying a general purpose
Slurm cluster or for using an existing Slurm cluster to run Cfiddle
jobs (although that is certainly possible).

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

In principle, the version of Linux shouldn't matter much, but some of the scripts will probably need to be adjusted.

We are using some moderately new docker features.  In particular, we
need docker-compose.yml 3.8, so you'll need at least Docker 19.03.

## Step 1:  Provisioning the Servers

We will assume you are setting up a cluster with one head node and two
workers.  Adding more workers is straightforward.  If you only have
two machines available, you can just build one worker

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

SSH into the head node.

Install git and clone this repo:


### Create A Docker Swarm

[Docker Swarm](https://docs.docker.com/engine/swarm/) is a tool for
orchestrating Docker containers across multiple machines.  It's going
to do all the heavy lifting of starting and tending to the Slurm nodes.

If you aren't familiar with swarm and/or the steps below don't work as expected, do the [swarm tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/).

First, create the swarm:

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



HEAD_ADDR=139.178.86.127
WORKER_1_ADDR=147.75.53.115
WORKER_0_ADDR=145.40.102.93



