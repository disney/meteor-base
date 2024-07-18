#!/usr/bin/env bash
source ./support.sh


exit_code=0 # Keep global, so that code below can get return value of this function
run_with_suppressed_output () {
	exit_code=0
	logs=$(eval "$1 2>&1") || exit_code=$?
	if [ $exit_code -ne 0 ]; then
		echo "$logs"
		exit $exit_code
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

	dockerfile='default.dockerfile'
	set_node_version "${version}"

	echo 'Creating test app...'
	run_with_suppressed_output "docker run --rm --volume ${PWD}:/opt/tmp --workdir /opt/tmp geoffreybooth/meteor-base:${version} meteor create --release=${version} test-app"

	cp "${dockerfile}" test.dockerfile
	do_sed "s|FROM geoffreybooth/meteor-base:.*|FROM geoffreybooth/meteor-base:${version}|" test.dockerfile

	# if we're using node version 14.21.4
	# we need to get the meteor/node image
	# else we use the official node image
	if [[ $(get_version_string "${node_version}") -ge $(get_version_string 14.21.4) && $(get_version_string "${node_version}") -lt $(get_version_string 18.0.0) ]]; then
		do_sed "s|FROM node:.*|FROM meteor/node:${node_version}|" test.dockerfile
	else
		do_sed "s|FROM node:.*|FROM node:${node_version}-alpine|" test.dockerfile
	fi

	do_sed "s|/app|/test-app|g" test.dockerfile

	cp docker-compose.yml test.docker-compose.yml
	do_sed 's|dockerfile: Dockerfile|dockerfile: test.dockerfile|' test.docker-compose.yml

	echo 'Building test app Docker image...'
	run_with_suppressed_output 'docker compose --file test.docker-compose.yml build'

	echo 'Launching test app...'
	run_with_suppressed_output 'docker compose --file test.docker-compose.yml up --detach'

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
		# For 14.21.4 <= $node_version < 18.0.0, we need to use the Meteor fork of the Node Docker image; else, we use the regular official Node Docker image
		if [[ $(get_version_string "${node_version}") -ge $(get_version_string 14.21.4) && $(get_version_string "${node_version}") -lt $(get_version_string 18.0.0) ]]; then
			printf "${RED}FAIL for geoffreybooth/meteor-base:${version} with meteor/node:${node_version}-alpine3.17${NC} after ${elapsed}\n"
		else
			printf "${RED}FAIL for geoffreybooth/meteor-base:${version} with node:${node_version}-alpine${NC} after ${elapsed}\n"
		fi
		at_least_one_failure=true
	else
		# For 14.21.4 <= $node_version < 18.0.0, we need to use the Meteor fork of the Node Docker image; else, we use the regular official Node Docker image
		if [[ $(get_version_string "${node_version}") -ge $(get_version_string 14.21.4) && $(get_version_string "${node_version}") -lt $(get_version_string 18.0.0) ]]; then
			printf "${GREEN}PASS for geoffreybooth/meteor-base:${version} with meteor/node:${node_version}-alpine3.17${NC} after ${elapsed}\n"
		else
			printf "${GREEN}PASS for geoffreybooth/meteor-base:${version} with node:${node_version}-alpine${NC} after ${elapsed}\n"
		fi
	fi

	if [ "${SKIP_CLEANUP:-}" != 1 ]; then
		run_with_suppressed_output 'docker compose --file test.docker-compose.yml down'
		run_with_suppressed_output 'docker rmi example-app:latest'

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
