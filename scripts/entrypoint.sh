#!/bin/bash

set -e

if [[ "$METEOR_SETTINGS_FILE" ]]; then
  echo "Settings meteor settings from secret"
  export METEOR_SETTINGS=$(cat $METEOR_SETTINGS_FILE)
fi

if [[ "$MONGO_URL_FILE" ]]; then
  echo "Settings mongo url from secret"
  export MONGO_URL=$(cat $MONGO_URL_FILE)
fi

if [[ "$MONGO_OPLOG_URL_FILE" ]]; then
  echo "Settings mongo oplog url from secret"
  export MONGO_OPLOG_URL=$(cat $MONGO_OPLOG_URL_FILE)
fi

if [[ "$REDIS_URI_FILE" ]]; then
  echo "Settings redis uri from secret"
  export REDIS_URI=$(cat $REDIS_URI_FILE)
fi

# try to start local MongoDB if no external MONGO_URL was set
if [[ "${MONGO_URL}" == *"127.0.0.1"* ]]; then
  if hash mongod 2>/dev/null; then
    printf "\n[-] External MONGO_URL not found. Starting local MongoDB...\n\n"
    exec gosu mongodb mongod --storageEngine=wiredTiger > /dev/null 2>&1 &
  else
    echo "ERROR: Mongo not installed inside the container."
    echo "Rebuild with INSTALL_MONGO=true in your launchpad.conf or supply a MONGO_URL environment variable."
    exit 1
  fi
fi

# Set a delay to wait to start the Node process
if [[ $STARTUP_DELAY ]]; then
  echo "Delaying startup for $STARTUP_DELAY seconds..."
  sleep $STARTUP_DELAY
fi

if [ "${1:0:1}" = '-' ]; then
	set -- node "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = "node" -a "$(id -u)" = "0" ]; then
	exec gosu node "$BASH_SOURCE" "$@"
fi

# Start app
echo "=> Starting app on port $PORT..."
exec "$@"
