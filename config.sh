
if ! [ -e install_slurm.sh ] ; then
    echo "You need to source this in the root of the cfiddle-cluster repo"
else
    export HEAD_ADDR=139.178.86.127
    export WORKER_1_ADDR=147.75.53.115
    export WORKER_0_ADDR=145.40.102.93

    export DOCKERHUB_USERNAME=stevenjswanson

    export SLURM_UID=990
    export SLURM_GID=990

    # these are the values that get set when I build the images.  Yours might be different.
    export MUNGE_UID=991
    export MUNGE_GID=991

    # create env variable aliases for the containers running our services, if we have docker available
    if which docker >/dev/null && docker container ls > /dev/null; then
	CONTAINER_ALIASES=$(docker container ls |perl -ne 'if (/ (slurm-stack_([^\.]*)-srv\.\S*)/) { print("export $2=$1\n");}')
	eval $CONTAINER_ALIASES
    fi
fi    
