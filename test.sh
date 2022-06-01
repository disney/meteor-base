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

	# Versions 1.9 through 2.2 need Node 12.22.1
	dockerfile='default.dockerfile'
	if [[ "${version}" == 1.9* ]] || [[ "${version}" == 1.10* ]] || [[ "${version}" == 1.11* ]] || [[ "${version}" == 1.12* ]] || [[ "${version}" == 2.0* ]] || [[ "${version}" == 2.1* ]] || [[ "${version}" == 2.2 ]]; then
		node_version='12.22.1'

	# Version 2.2.1 needs Node 12.22.2
	elif [[ "${version}" == 2.2.1 ]]; then
		node_version='12.22.2'

	# Version 2.2.2 needs Node 12.22.4
	elif [[ "${version}" == 2.2.2 ]]; then
		node_version='12.22.4'

	# Version 2.2.3 needs Node 12.22.5
	elif [[ "${version}" == 2.2.3 ]]; then
		node_version='12.22.5'

	# Version 2.3 needs Node 14.17.1
	elif [[ "${version}" == 2.3 ]]; then
		node_version='14.17.1'

	# Versions 2.3.1 and 2.3.2 need Node 14.17.3
	elif [[ "${version}" == 2.3.1 ]] || [[ "${version}" == 2.3.2 ]]; then
		node_version='14.17.3'

	# Versions 2.3.3 and 2.3.4 need Node 14.17.4
	elif [[ "${version}" == 2.3.3 ]] || [[ "${version}" == 2.3.4 ]]; then
		node_version='14.17.4'

	# Version 2.3.5 needs Node 14.17.5
	elif [[ "${version}" == 2.3.5 ]]; then
		node_version='14.17.5'

	# Version 2.3.6 and 2.4 need Node 14.17.6
	elif [[ "${version}" == 2.3.6 ]] || [[ "${version}" == 2.4 ]]; then
		node_version='14.17.6'

	# Version 2.5 needs Node 14.18.1
	elif [[ "${version}" == 2.5 ]]; then
		node_version='14.18.1'

	# Versions from 2.5.1 to 2.5.5 are unsupported because the Fibers version is missing binaries

	# Versions 2.5.6, 2.6 and 2.6.1 need Node 14.18.3
	elif [[ "${version}" == 2.5.6 ]] || [[ "${version}" == 2.6 ]] || [[ "${version}" == 2.6.1 ]]; then
		node_version='14.18.3'

	# Versions >= 2.7 need Node 14.19.1
	else
		node_version='14.19.1'
	fi

	echo 'Creating test app...'
	run_with_suppressed_output "docker run --rm --volume ${PWD}:/opt/tmp --workdir /opt/tmp geoffreybooth/meteor-base:${version} meteor create --release=${version} test-app"

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
		printf "${RED}FAIL for geoffreybooth/meteor-base:${version} with node:${node_version}-alpine${NC} after ${elapsed}\n"
		at_least_one_failure=true
	else
		printf "${GREEN}PASS for geoffreybooth/meteor-base:${version} with node:${node_version}-alpine${NC} after ${elapsed}\n"
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
