#!/bin/bash

set -o errexit

printf "\n[-] Building Meteor application bundle...\n"
printf "\n    This container can use `free -m | grep Mem: | awk '{print $2}'`M memory in total."
printf "\n    If it aborts with an out-of-memory (OOM) or ‘non-zero exit code 137’ error message,"
printf "\n    please increase the container’s available memory.\n"
printf "\n    See https://github.com/meteor/meteor/issues/9568 for details.\n\n"

mkdir --parents $APP_BUNDLE_FOLDER

cd $APP_SOURCE_FOLDER

meteor build --directory $APP_BUNDLE_FOLDER --server-only
