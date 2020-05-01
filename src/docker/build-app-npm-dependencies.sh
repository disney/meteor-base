#!/bin/bash

set -o errexit

printf "\n[-] Installing app NPM dependencies...\n\n"

cd $APP_SOURCE_FOLDER

meteor npm ci || meteor npm install # The latter is for older versions of Meteor that ship with npm < 5.7.0
