#!/usr/bin/bash

for i in 1 2 3 4 5 6 7 8 9; do
    salloc -t 1 srun sleep 2 > /dev/null 2>&1 &
done

watch squeue -a
