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
newest_meteor_version="${meteor_versions[-1]}"

do_sed $"s|          - '${newest_meteor_version}'|          - '${newest_meteor_version}'\\n          - '${new_meteor_version}'|" ./.github/workflows/continuous-integration-workflow.yml

do_sed "s|${newest_meteor_version}|${new_meteor_version}|" ./README.md

do_sed "s|${newest_meteor_version}|${new_meteor_version}|" ./example/app-with-native-dependencies.dockerfile

# Skip ./example/app/.meteor/release because the Meteor update command below will change it

do_sed "s|${newest_meteor_version}|${new_meteor_version}|" ./example/default.dockerfile

do_sed $"s|'${newest_meteor_version}'|'${newest_meteor_version}' \\\\\n	'${new_meteor_version}'|" ./versions.sh


# Update files for new Node version

set_node_version $newest_meteor_version # $node_version is the version of the current newest Meteor version, not the one being added

do_sed "s|${node_version}|${new_node_version}|" ./example/app-with-native-dependencies.dockerfile

do_sed "s|${node_version}|${new_node_version}|" ./example/default.dockerfile


# Update example app dependencies

cd example/app

meteor update --release "${new_meteor_version}"

npm-check-updates --configFilePath /dev/null --upgrade
npm install

cd ../..
