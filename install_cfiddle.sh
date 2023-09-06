#!/usr/bin/env bash
set -ex

python -V

if ! [ -e cfiddle ]; then
    git clone -b devel http://github.com/NVSL/cfiddle
fi
pushd cfiddle;
bin/cfiddle_install_prereqs.sh
python -m 'pip' install cfiddle .
popd


if ! [ -e delegate-function ]; then
    git clone -b devel http://github.com/NVSL/delegate-function
fi
pushd delegate-function
python -m 'pip' install cfiddle .
popd



