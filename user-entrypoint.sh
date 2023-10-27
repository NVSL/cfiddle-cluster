#!/usr/bin/bash

set -ex

export PATH=$PATH:/opt/conda/bin
echo here "$@"
cd $HOME
exec "$@"


