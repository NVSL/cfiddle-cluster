
if ! [ -e IMAGE_TAG ] ; then
    echo "You need to source this in the root of the cfiddle-cluster repo"
else
    export HEAD_ADDR=139.178.86.127
    export WORKER_1_ADDR=147.75.53.115
    export WORKER_0_ADDR=145.40.102.93

    export DOCKERHUB_USERNAME=stevenjswanson
    export IMAGE_TAG=$(cat IMAGE_TAG)

    export SLURM_UID=990
    export SLURM_GID=990

    # these are the values that get set when I build the images.  Yours might be different.
    export MUNGE_UID=102 
    export MUNGE_GID=102
    
fi    
