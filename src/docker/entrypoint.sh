#!/bin/bash

set -o errexit

cd $SCRIPTS_FOLDER

# Source an init script that a child image may have added
if [ -x ./startup.sh ]; then
	source ./startup.sh
fi

# Poll until we can successfully connect to MongoDB
source ./connect-to-mongo.sh

echo 'Starting app...'
cd $APP_BUNDLE_FOLDER/bundle

exec "$@"
