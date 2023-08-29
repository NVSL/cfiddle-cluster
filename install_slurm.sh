#!/usr/bin/env bash
set -ex


if ! [ -z ${1+x} ] && [ $1 = "--client-only" ]; then
CLIENT_ONLY=$1
else
CLIENT_ONLY="no"
fi


SLURM_TAG=$(cat SLURM_TAG)
IMAGE_TAG=$(cat IMAGE_TAG)
GOSU_VERSION=1.11

groupadd -r --gid=$SLURM_GID slurm 
useradd -r -g slurm --uid=$SLURM_UID slurm

groupadd -r --gid=$MUNGE_GID munge 
useradd -r -g munge --uid=$MUNGE_UID munge

apt-get update --fix-missing --allow-releaseinfo-change

if [ $CLIENT_ONLY = "no" ]; then
apt-get install -y \
	gnupg \
	mariadb-server \
	psmisc \
	bash-completion \
	slurmd slurm slurm-client slurmdbd slurmctld \
	munge
else
apt-get install -y slurm-client munge
fi

# the step above generate /etc/munge.key, so it's shared across all the containers.
# so we don't need this:
# /sbin/create-munge-key

apt-get clean -y


if [ $CLIENT_ONLY = "no" ]; then
mkdir -p /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/slurmdbd \
        /var/lib/slurmd \
        /var/log/slurm \
        /data
fi

mkdir -p /etc/slurm/
cp slurm.conf /etc/slurm/slurm.conf
cp slurmdbd.conf /etc/slurm/slurmdbd.conf

if [ $CLIENT_ONLY = "no" ]; then
touch /var/lib/slurmd/node_state \
        /var/lib/slurmd/front_end_state \
        /var/lib/slurmd/job_state \
        /var/lib/slurmd/resv_state \
        /var/lib/slurmd/trigger_state \
        /var/lib/slurmd/assoc_mgr_state \
        /var/lib/slurmd/assoc_usage \
        /var/lib/slurmd/qos_usage \
        /var/lib/slurmd/fed_mgr_state
# the entrypoint script uses this.
set -ex \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

chown -R slurm:slurm /var/*/slurm*
fi


chown slurm:slurm /etc/slurm/slurmdbd.conf
chmod 600 /etc/slurm/slurmdbd.conf

#echo "NodeName=$(hostname) RealMemory=1000 State=UNKNOWN" >> /etc/slurm/slurm.conf
