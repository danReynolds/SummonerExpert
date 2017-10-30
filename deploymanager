#!/bin/sh

DEPLOY_COMMAND=${1:-"rake docker:build"}

if [ -z "${ENV_KEY}" ]; then
  echo "Missing ENV_KEY environment variable."
  return
fi

if [ -z "${DEPLOY_TAG}" ]; then
  echo "Missing DEPLOY_TAG environment variable."
  return
fi

docker run -e DEPLOY_COMMAND="$DEPLOY_COMMAND" -e DEPLOY_TAG=$DEPLOY_TAG -e ENV_KEY=$ENV_KEY -v $PWD:/app:rw -v /var/run/docker.sock:/var/run/docker.sock --env-file .env danreynolds/deploymanager:0.0.24
