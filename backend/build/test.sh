#!/bin/sh
# wait for server
export PYTHONUNBUFFERED=1
sleep 1
exec pytest -v /opt/tests
