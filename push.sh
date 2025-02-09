#!/usr/bin/env bash
source ./support.sh
source ./versions.sh


for version in "${versions[@]}"; do
	printf "${GREEN}Pushing Docker base image for Meteor ${version}...${NC}\n"
	if ! docker push geoffreybooth/meteor-base:"${version}"; then
		printf "${RED}Error pushing Docker base image for Meteor ${version}${NC}\n"
		exit 1
	fi

	if [[ $version == $latest_version ]]; then
		if ! docker push geoffreybooth/meteor-base:latest; then
			printf "${RED}Error pushing Docker base image for Meteor (latest version)${NC}\n"
			exit 1
		fi
	fi
done


if [[ "${#versions[@]}" -eq 1 ]]; then
	printf "${GREEN}Success pushing Docker base image for Meteor ${versions}"
	if [[ "${versions[0]}" == $latest_version ]]; then
		printf " (latest version)\n"
	else
		printf "\n"
else
	printf "${GREEN}Success pushing Docker base images for all supported Meteor versions\n"
fi
