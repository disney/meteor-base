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
	'2.3' \
	'2.3.1' \
	'2.3.2' \
	'2.3.3' \
	'2.3.4' \
	'2.3.5' \
	'2.3.6' \
	'2.4' \
	'2.5' \
	# '2.5.1' \ # Fibers is missing binaries
	# '2.5.2' \ # Fibers is missing binaries
	# '2.5.3' \ # Fibers is missing binaries
	# '2.5.4' \ # Fibers is missing binaries
	# '2.5.5' \ # Fibers is missing binaries
	'2.5.6' \
	'2.6' \
	'2.6.1' \
	'2.7' \
	'2.7.1' \
	'2.7.2' \
	'2.7.3'
)


set_node_version() {
	# Versions 1.9 through 2.2 need Node 12.22.1
	if [[ "$1" == 1.9* ]] || \
		[[ "$1" == 1.10* ]] || \
		[[ "$1" == 1.11* ]] || \
		[[ "$1" == 1.12* ]] || \
		[[ "$1" == 2.0* ]] || \
		[[ "$1" == 2.1* ]] || \
		[[ "$1" == 2.2 ]]; then node_version='12.22.1'
	elif [[ "$1" == 2.2.1 ]]; then node_version='12.22.2'
	elif [[ "$1" == 2.2.2 ]]; then node_version='12.22.4'
	elif [[ "$1" == 2.2.3 ]]; then node_version='12.22.5'
	elif [[ "$1" == 2.3 ]]; then node_version='14.17.1'
	elif [[ "$1" == 2.3.1 ]]; then node_version='14.17.3'
	elif [[ "$1" == 2.3.2 ]]; then node_version='14.17.3'
	elif [[ "$1" == 2.3.3 ]]; then node_version='14.17.4'
	elif [[ "$1" == 2.3.4 ]]; then node_version='14.17.4'
	elif [[ "$1" == 2.3.5 ]]; then node_version='14.17.5'
	elif [[ "$1" == 2.3.6 ]]; then node_version='14.17.6'
	elif [[ "$1" == 2.4 ]]; then node_version='14.17.6'
	elif [[ "$1" == 2.5 ]]; then node_version='14.18.1'
	# Versions from 2.5.1 to 2.5.5 are unsupported because the Fibers version is missing binaries
	elif [[ "$1" == 2.5.6 ]]; then node_version='14.18.3'
	elif [[ "$1" == 2.6 ]]; then node_version='14.18.3'
	elif [[ "$1" == 2.6.1 ]]; then node_version='14.18.3'
	elif [[ "$1" == 2.7.0 ]]; then node_version='14.19.1'
	elif [[ "$1" == 2.7.1 ]]; then node_version='14.19.1'
	elif [[ "$1" == 2.7.2 ]]; then node_version='14.19.1'
	elif [[ "$1" == 2.7.3 ]]; then node_version='14.19.3'
	fi # End of versions
}
