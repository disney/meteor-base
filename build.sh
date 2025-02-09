#!/usr/bin/env bash
source ./support.sh
source ./versions.sh


build_cmd() {
	docker build --build-arg "METEOR_VERSION=$1" --tag geoffreybooth/meteor-base:"$1" ./src
	if [[ $1 == $latest_version ]]; then
		docker tag geoffreybooth/meteor-base:"$1" geoffreybooth/meteor-base:latest
	fi
}

build() {
	# Retry up to five times
	build_cmd $1 || build_cmd $1 || build_cmd $1 || build_cmd $1 || build_cmd $1
}


for version in "${versions[@]}"; do
	printf "${GREEN}Building Docker base image for Meteor ${version}...${NC}\n"
	if ! build $version; then
		printf "${RED}Error building Docker base image for Meteor ${version}${NC}\n"
		exit 1
	fi
done


if [[ "${#versions[@]}" -eq 1 ]]; then
	printf "${GREEN}Success building Docker base image for Meteor ${versions}\n"
else
	printf "${GREEN}Success building Docker base images for all supported Meteor versions\n"
fi
