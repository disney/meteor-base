#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
set -o allexport


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'


exit_code=0 # Keep global, so that code below can get return value of this function
run_with_suppressed_output () {
	exit_code=0
	logs=$(eval "$1 2>&1") || exit_code=$?
	if [ $exit_code -ne 0 ]; then
		echo "$logs"
		exit $exit_code
	fi
}


do_sed () {
	if [ "$(uname)" == "Darwin" ]; then # Mac
		sed -i '' -e "$1" "$2"
	else # Linux
		sed --in-place "$1" "$2"
	fi
}


source ./versions.sh

if [ -n "${CI_VERSION:-}" ]; then
	meteor_versions=( "$CI_VERSION" )
elif [[ "${1-x}" != x ]]; then
	meteor_versions=( "$1" )
fi

cd example

at_least_one_failure=false
for version in "${meteor_versions[@]}"; do
	printf "${YELLOW}Testing Docker image geoffreybooth/meteor-base:${version}...${NC}\n"
	SECONDS=0

	rm -f test.dockerfile
	rm -f test.docker-compose.yml
	rm -rf test-app

	# Versions < 1.8.1 need app-with-native-dependencies.dockerfile
	dockerfile='default.dockerfile'
	if [[ "${version}" == 1.6* ]] || [[ "${version}" == 1.7* ]] || [[ "${version}" == 1.8 ]] || [[ "${version}" == 1.8.0* ]]; then
		dockerfile='app-with-native-dependencies.dockerfile'
	fi

	node_version='12.16.1'
	# Versions < 1.9 need Node 8.17.0
	if [[ "${version}" == 1.6* ]] || [[ "${version}" == 1.7* ]] || [[ "${version}" == 1.8* ]]; then
		node_version='8.17.0'
	fi

	echo 'Creating test app...'
	run_with_suppressed_output "docker run --rm --volume ${PWD}:/opt/tmp --workdir /opt/tmp geoffreybooth/meteor-base:${version} meteor create --release=${version} test-app"

	if [[ "${version}" == 1.6.1* ]] || [[ "${version}" == 1.7 ]] || [[ "${version}" == 1.7.0* ]]; then
		echo 'Fixing Babel dependency...'
		cd ./test-app
		run_with_suppressed_output "docker run --rm --volume ${PWD}:/opt/tmp --workdir /opt/tmp geoffreybooth/meteor-base:${version} meteor npm install --save-exact @babel/runtime@7.0.0-beta.55"
		cd ..
	fi

	if [[ "${version}" == 1.8* ]]; then
		echo 'Fixing jQuery dependency...'
		cd ./test-app
		run_with_suppressed_output "docker run --rm --volume ${PWD}:/opt/tmp --workdir /opt/tmp geoffreybooth/meteor-base:${version} meteor npm install jquery"
		cd ..
	fi

	cp "${dockerfile}" test.dockerfile
	do_sed "s|FROM geoffreybooth/meteor-base:.*|FROM geoffreybooth/meteor-base:${version}|" test.dockerfile
	do_sed "s|FROM node:.*|FROM node:${node_version}-alpine|" test.dockerfile
	do_sed "s|/app|/test-app|g" test.dockerfile

	cp docker-compose.yml test.docker-compose.yml
	do_sed 's|dockerfile: Dockerfile|dockerfile: test.dockerfile|' test.docker-compose.yml

	echo 'Building test app Docker image...'
	run_with_suppressed_output 'docker-compose --file test.docker-compose.yml build'

	echo 'Launching test app...'
	run_with_suppressed_output 'docker-compose --file test.docker-compose.yml up --detach'

	# Poll until docker-compose network ready, timing out after 20 seconds
	for i in {1..20}; do
		(curl --silent --fail http://localhost/ | grep __meteor_runtime_config__) > /dev/null 2>&1 && break || {
			if [ "$i" -lt 21 ]; then
				sleep 1
			else
				printf "${RED}App failed to start${NC}\n"
			fi
		}
	done

	echo 'Running test...'
	if [ ! -d ../test/node_modules ]; then
		cd ../test
		run_with_suppressed_output 'npm ci'
		cd ../example
	fi
	run_with_suppressed_output 'node ../test/test.js' || true # Don’t exit if tests fail
	elapsed="$((($SECONDS / 60) % 60)) min $(($SECONDS % 60)) sec"
	if [ $exit_code -ne 0 ]; then
		printf "${RED}FAIL for geoffreybooth/meteor-base:${version}${NC} after ${elapsed}\n"
		at_least_one_failure=true
	else
		printf "${GREEN}PASS for geoffreybooth/meteor-base:${version}${NC} after ${elapsed}\n"
	fi

	if [ "${SKIP_CLEANUP:-}" != 1 ]; then
		run_with_suppressed_output 'docker-compose --file test.docker-compose.yml down'
		run_with_suppressed_output 'docker rmi example_app:latest'

		rm -f test.dockerfile
		rm -f test.docker-compose.yml
		rm -rf test-app
	fi
done

if $at_least_one_failure ; then
	printf "${RED}FAIL! At least one image failed the test${NC}\n"
	exit 1
else
	printf "${GREEN}PASS! All images passed the test${NC}\n"
	exit 0
fi
