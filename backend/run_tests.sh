#!/bin/sh
COMMON_ARGS="-f docker-compose-test.yaml -p backend_test"

docker-compose $COMMON_ARGS run --rm tests "$@"
docker-compose $COMMON_ARGS exec briefthreat rm /tmp/test.db
docker-compose $COMMON_ARGS stop
