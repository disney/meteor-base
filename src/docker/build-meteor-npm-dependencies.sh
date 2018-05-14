#!/bin/bash

set -o errexit

printf "\n[-] Installing Meteor application server NPM dependencies...\n\n"

cd $APP_BUNDLE_FOLDER/bundle/programs/server/

if hash npm 2>/dev/null; then
	npm install
else
	meteor npm install
fi
