#!/bin/sh
export PYTHONUNBUFFERED=1
export PYTHONPATH=/opt/tests:$PYTHONPATH

# wait for server
until curl -sf http://briefthreat:8080/health > /dev/null; do
  echo waiting for app server...
  sleep 0.1
done

exec pytest /opt/tests "$@"
