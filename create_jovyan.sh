#!/usr/bin/bash

set -ex

# this our test user and the user built in to the jupyter hub image we use for testing.  That's where the uid and gids come from.
useradd -p jovyan -g 100 -u 1000 jovyan -m
