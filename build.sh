#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
set -o allexport


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'


build_cmd() {
	docker build --build-arg "METEOR_VERSION=$1" --tag geoffreybooth/meteor-base:"$1" ./src
}

build() {
	# Retry up to five times
	build_cmd $1 || build_cmd $1 || build_cmd $1 || build_cmd $1 || build_cmd $1
}


source ./versions.sh

building_all_versions=true
if [ -n "${CI_VERSION:-}" ]; then
	meteor_versions=( "${CI_VERSION:-}" )
	building_all_versions=false
elif [[ "${1-x}" != x ]]; then
	meteor_versions=( "$1" )
	building_all_versions=false
fi


for version in "${meteor_versions[@]}"; do
	printf "${GREEN}Building Docker base image for Meteor ${version}...${NC}\n"
	if ! build $version; then
		printf "${RED}Error building Docker base image for Meteor ${version}${NC}\n"
		exit 1
	fi
done

if [[ $building_all_versions ]]; then
	docker tag geoffreybooth/meteor-base:"${version}" geoffreybooth/meteor-base:latest
	printf "${GREEN}Success building Docker base images for all supported Meteor versions\n"
else
	printf "${GREEN}Success building Docker base images for Meteor versions ${meteor_versions}\n"
fi
