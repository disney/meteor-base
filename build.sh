#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
set -o allexport


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'


source ./versions.sh

for version in "${meteor_versions[@]}"; do
	printf "${GREEN}Building Docker base image for Meteor ${version}...${NC}\n"
	if ! docker build --build-arg "METEOR_VERSION=${version}" --tag gee-docker.mtnsat.io/meteor-base:"${version}" ./src; then
		printf "${RED}Error building Docker base image for Meteor ${version}${NC}\n"
		exit 1
	fi
done
printf "${GREEN}Success building Docker base images for all supported Meteor versions\n"
