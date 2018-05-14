#!/bin/bash

set -o errexit

printf "\n[-] Installing app NPM dependencies...\n\n"

cd $APP_SOURCE_FOLDER

meteor npm install
