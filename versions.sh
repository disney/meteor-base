#!/usr/bin/env bash

# Versions to build this Docker image for
meteor_versions=( \
	'1.9' \
	'1.9.1' \
	'1.9.2' \
	'1.9.3' \
	# '1.10' \ # Not hosted
	'1.10.1' \
	'1.10.2' \
	'1.11' \
	'1.11.1' \
	'1.12' \
	'1.12.1' \
	'2.0' \
	'2.1' \
	'2.1.1' \
	'2.2' \
	'2.2.1' \
	'2.2.2' \
	'2.2.3' \
	'2.2.4' \
	'2.3' \
	'2.3.1' \
	'2.3.2' \
	'2.3.3' \
	'2.3.4' \
	'2.3.5' \
	'2.3.6' \
	'2.3.7' \
	'2.4' \
	'2.5' \
	# '2.5.1' \ # Fibers is missing binaries
	# '2.5.2' \ # Fibers is missing binaries
	# '2.5.3' \ # Fibers is missing binaries
	# '2.5.4' \ # Fibers is missing binaries
	# '2.5.5' \ # Fibers is missing binaries
	'2.5.6' \
	'2.5.7' \
	'2.5.8' \
	'2.6' \
	'2.6.1' \
	'2.7' \
	'2.7.1' \
	'2.7.2' \
	'2.7.3' \
	'2.8.0' \
	'2.8.1' \
	'2.9.0' \
	'2.9.1' \
	'2.10.0' \
	'2.11.0' \
	'2.12' \
	'2.13' \
	'2.13.1' \
	'2.13.3' \
	'2.14' \
	'2.15' \
	'2.16' \
	'3.0.1' \
	'3.0.2' \
	'3.0.3' \
	'3.0.4' \
	'3.1' \
	'3.1.1' \
	'3.1.2' \
	'3.2' \
	'3.3'
)

latest_version="${meteor_versions[*]: -1}"

# Get the array of versions to loop through, either a particular single version passed in or all of the versions listed above
if [ -n "${CI_VERSION:-}" ]; then
	versions=( "$CI_VERSION" )
elif [[ "${1-x}" != x ]]; then
	versions=( "$1" )
else
	versions=( "${meteor_versions[@]}" )
fi
