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

if [[ $(get_version_string "${new_node_version}") -ge $(get_version_string 18.0.0) ]]; then

	node_image_keyword='node:'
	meteor_node_image_keyword='meteor/node:'

	node_alpine_keyword='alpine'
	meteor_node_alpine_keyword='alpine3.17'

	do_sed "s|${meteor_node_image_keyword}|${node_image_keyword}|g" ./example/app-with-native-dependencies.dockerfile

	do_sed "s|${node_version}|${new_node_version}|g" ./example/app-with-native-dependencies.dockerfile

	do_sed "s|${meteor_node_alpine_keyword}|${node_alpine_keyword}|g" ./example/app-with-native-dependencies.dockerfile

	do_sed "s|${meteor_node_image_keyword}|${node_image_keyword}|g" ./example/default.dockerfile

	do_sed "s|${node_version}|${new_node_version}|g" ./example/default.dockerfile

	do_sed "s|${meteor_node_alpine_keyword}|${node_alpine_keyword}|g" ./example/default.dockerfile

else

	do_sed "s|${node_version}|${new_node_version}|g" ./example/app-with-native-dependencies.dockerfile

	do_sed "s|${node_version}|${new_node_version}|g" ./example/default.dockerfile

fi


# Use cat here because the file is being written to in the same command
# Reverse the file, replace the first occurrence of the current node version with __XXXXXX__ as placeholder,
# reverse the file back, replace __XXXXXX__ back and add new line for the new Meteor version, and write the file back
cat ./support.sh \
	| do_tac \
	| sed "1,/'${node_version}'/s|'${node_version}'|'__XXXXXX__'|" \
	| do_tac \
	| sed "s|'__XXXXXX__'|'${node_version}'\\n	elif [[ \"\$1\" == ${new_meteor_version} ]]; then node_version='${new_node_version}'|" \
	| tee -i ./support.sh > /dev/null


# Update example app dependencies

cd example/app

meteor update --release "${new_meteor_version}"

npm-check-updates --configFilePath /dev/null --upgrade
npm install

cd ../..
