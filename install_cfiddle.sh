#!/usr/bin/env bash
set -ex

if ! [ -e cfiddle ]; then
    git clone -b devel http://github.com/NVSL/cfiddle
fi
pushd cfiddle;
bin/cfiddle_install_prereqs.sh
pip install cfiddle .
popd


if ! [ -e delegate-function ]; then
    git clone -b devel http://github.com/NVSL/delegate-function
fi
pushd delegate-function
pip install cfiddle .
popd



