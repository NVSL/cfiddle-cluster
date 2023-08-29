#!/bin/bash
set -ex

if [ "$1" = "start-notebook.sh" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    service munge start
fi

echo "$@"
exec su jovyan -- -c "user-entrypoint.sh $@"
