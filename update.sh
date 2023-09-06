#!/usr/bin/env bash
source ./support.sh


# Check for dependencies

if ! which meteor > /dev/null ; then
	echo 'Error: Meteor must be installed.'
	echo 'See https://www.meteor.com/developers/install'
	exit 1
fi

if ! which npm-check-updates > /dev/null ; then
	echo 'Error: npm-check-updates must be installed:'
	echo 'npm install --global npm-check-updates'
	exit 1
fi


# Parse arguments

help() {
	echo 'Add new Meteor release version, including the version of Node.js that it needs per the Meteor changelog'
	echo 'syntax: ./update.sh --meteor-version 0.0.0 --node-version 0.0.0'
}


if [ $# -eq 0 ]; then
	help
	exit 0
fi

new_meteor_version=''
new_node_version=''

while test $# -gt 0; do
	case "$1" in
		-h|--help)
			help
			exit 0
			;;
		--meteor-version)
			shift;
			new_meteor_version="$1";
			shift;
			;;
		--node-version)
			shift;
			new_node_version="$1";
			shift;
			;;
		*)
			help
			exit 0
			;;
	esac
done

# Use printf to get appropriate version string for comparison
get_version_string() {
	printf "%02d%02d%02d" $(echo "$1" | tr '.' ' ');
}

# Update files for new Meteor version

source ./versions.sh
newest_meteor_version="${meteor_versions[*]: -1}"

do_sed $"s|          - '${newest_meteor_version}'|          - '${newest_meteor_version}'\\n          - '${new_meteor_version}'|" ./.github/workflows/continuous-integration-workflow.yml

do_sed "s|${newest_meteor_version}|${new_meteor_version}|g" ./README.md

do_sed "s|${newest_meteor_version}|${new_meteor_version}|g" ./example/app-with-native-dependencies.dockerfile

# Skip ./example/app/.meteor/release because the Meteor update command below will change it

do_sed "s|${newest_meteor_version}|${new_meteor_version}|g" ./example/default.dockerfile

do_sed $"s|'${newest_meteor_version}'|'${newest_meteor_version}' \\\\\n	'${new_meteor_version}'|" ./versions.sh


# Update files for new Node version

set_node_version $newest_meteor_version # $node_version is the version of the current newest Meteor version, not the one being added

# For 14.21.4 <= $new_node_version < 18.0.0, we need to use the Meteor fork of the Node Docker image; else, we use the regular official Node Docker image

if [[ $(get_version_string "${new_node_version}") -ge $(get_version_string 14.21.4) && $(get_version_string "${new_node_version}") -lt $(get_version_string 18.0.0) ]]; then

	node_image_keyword='node:'
	meteor_node_image_keyword='meteor/node:'

	node_alpine_keyword='alpine'
	meteor_node_alpine_keyword='alpine3.17'

	do_sed "s|${node_image_keyword}|${meteor_node_image_keyword}|g" ./example/app-with-native-dependencies.dockerfile

	do_sed "s|${node_version}|${new_node_version}|g" ./example/app-with-native-dependencies.dockerfile

	do_sed "s|${node_alpine_keyword}|${meteor_node_alpine_keyword}|g" ./example/app-with-native-dependencies.dockerfile

	do_sed "s|${node_image_keyword}|${meteor_node_image_keyword}|g" ./example/default.dockerfile

	do_sed "s|${node_version}|${new_node_version}|g" ./example/default.dockerfile

	do_sed "s|${node_alpine_keyword}|${meteor_node_alpine_keyword}|g" ./example/default.dockerfile

else

	do_sed "s|${node_version}|${new_node_version}|g" ./example/app-with-native-dependencies.dockerfile

	do_sed "s|${node_version}|${new_node_version}|g" ./example/default.dockerfile

fi

do_sed $"s|'${node_version}'|'${node_version}'\\n	elif [[ \"\$1\" == ${new_meteor_version} ]]; then node_version='${new_node_version}'|" ./support.sh


# Update example app dependencies

cd example/app

meteor update --release "${new_meteor_version}"

npm-check-updates --configFilePath /dev/null --upgrade
npm install

cd ../..
