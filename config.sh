if ! [ -e install_slurm.sh ] ; then
    echo "You need to source this in the root of the cfiddle-cluster repo"
else
    export HEAD_ADDR=139.178.86.127
    export WORKER_ADDRS="147.75.53.115 145.40.102.93"
    export DOCKERHUB_USERNAME=stevenjswanson

    export SLURM_UID=990
    export SLURM_GID=990

    # these are the values that get set when I build the images.  Yours might be different.
    export MUNGE_UID=991
    export MUNGE_GID=991

    export DELEGATE_FUNCTION_GIT_TAG=main
    export CFIDDLE_GIT_TAG=devel
    
    # create env variable aliases for the containers running our services, if we have docker available
    if which docker >/dev/null && docker container ls > /dev/null; then
	CONTAINER_ALIASES=$(docker container ls |perl -ne 'if (/ (slurm-stack_([^\.]*)-srv\.\S*)/) { print("export $2=$1\n");}')
	eval $CONTAINER_ALIASES
    fi
fi    
