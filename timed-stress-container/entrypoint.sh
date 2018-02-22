#!/bin/bash
set -e

/usr/bin/stress --verbose "$@"

while :
do
    sleep 60
done
