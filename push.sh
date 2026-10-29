#!/usr/bin/env bash
source ./support.sh
source ./versions.sh

default_amd64_platforms="${DOCKER_PLATFORMS_AMD64_ONLY:-linux/amd64}"
default_multi_arch_platforms="${DOCKER_PLATFORMS_MULTI_ARCH:-linux/amd64,linux/arm64}"

if ! docker buildx version > /dev/null 2>&1; then
	printf "${RED}Error: docker buildx is required to push multi-arch images${NC}\n"
	exit 1
fi


for version in "${versions[@]}"; do
	printf "${GREEN}Pushing Docker base image for Meteor ${version}...${NC}\n"
	platforms="${DOCKER_PLATFORMS:-}"
	if [[ -z "${platforms}" ]]; then
		if [[ "${version}" == 3.* ]]; then
			platforms="${default_multi_arch_platforms}"
		else
			platforms="${default_amd64_platforms}"
		fi
	fi

	tags=( --tag geoffreybooth/meteor-base:"${version}" )
	if [[ $version == $latest_version ]]; then
		tags+=( --tag geoffreybooth/meteor-base:latest )
	fi

	if ! docker buildx build \
		--platform "${platforms}" \
		--build-arg "METEOR_VERSION=${version}" \
		"${tags[@]}" \
		--push \
		./src; then
		printf "${RED}Error pushing Docker base image for Meteor ${version}${NC}\n"
		exit 1
	fi
done


if [[ "${#versions[@]}" -eq 1 ]]; then
	printf "${GREEN}Success pushing Docker base image for Meteor ${versions}"
	if [[ "${versions[0]}" == $latest_version ]]; then
		printf " (latest version)\n"
	else
		printf "\n"
	fi
else
	printf "${GREEN}Success pushing Docker base images for all supported Meteor versions\n"
fi
