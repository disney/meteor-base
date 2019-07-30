#!/bin/bash

set -o errexit

printf "\n[-] Installing Meteor application server NPM dependencies...\n\n"

if hash npm 2>/dev/null; then
	npm_cmd='npm'
else
	npm_cmd='meteor npm'
fi

cd $APP_BUNDLE_FOLDER/bundle/programs/server/
$npm_cmd install

if [[ "$1" = '--build-from-source' ]]; then
	$npm_cmd rebuild --build-from-source
	cd $APP_BUNDLE_FOLDER/bundle/programs/server/npm
	$npm_cmd rebuild --build-from-source
fi
