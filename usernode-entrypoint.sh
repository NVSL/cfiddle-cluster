#!/bin/bash
set -ex

if [ "$1" = "start-notebook.sh" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    service munge start
fi

echo there "$@"
# the business with base64 lets us pass arbitrary commands to su
# https://serverfault.com/a/625697
echo "user-entrypoint.sh $@" | base64 -w0 | exec su jovyan -- -c "base64 -d | bash"
