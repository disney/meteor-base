set -o errexit
set -o pipefail
set -o nounset
set -o allexport


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'


do_sed () {
	if [ "$(uname)" == "Darwin" ]; then # Mac
		sed -i '' -e "$1" "$2"
	else # Linux
		sed --in-place "$1" "$2"
	fi
}

# Reverse the file from filename or stdin
do_tac () {
	if [ "$(uname)" == "Darwin" ]; then # Mac
		# macOS doesn't have tac, so we use tail -r
		if (( $# == 0 )) ; then
			tail -r < /dev/stdin
		else
			tail -r "$1"
		fi
	else # Linux
		# linux doesn't have -r option for tail
		if (( $# == 0 )) ; then
			tac < /dev/stdin
		else
			tac "$1"
		fi
	fi
}


set_node_version() {
	# Versions 1.9 through 2.2 need Node 12.22.1
	if [[ "$1" == 1.9* ]] || \
		[[ "$1" == 1.10* ]] || \
		[[ "$1" == 1.11* ]] || \
		[[ "$1" == 1.12* ]] || \
		[[ "$1" == 2.0 ]] || \
		[[ "$1" == 2.1 ]] || \
		[[ "$1" == 2.1.1 ]] || \
		[[ "$1" == 2.2 ]]; then node_version='12.22.1'
	elif [[ "$1" == 2.2.1 ]]; then node_version='12.22.2'
	elif [[ "$1" == 2.2.2 ]]; then node_version='12.22.4'
	elif [[ "$1" == 2.2.3 ]]; then node_version='12.22.5'
	elif [[ "$1" == 2.2.4 ]]; then node_version='12.22.5'
	elif [[ "$1" == 2.3 ]]; then node_version='14.17.1'
	elif [[ "$1" == 2.3.1 ]]; then node_version='14.17.3'
	elif [[ "$1" == 2.3.2 ]]; then node_version='14.17.3'
	elif [[ "$1" == 2.3.3 ]]; then node_version='14.17.4'
	elif [[ "$1" == 2.3.4 ]]; then node_version='14.17.4'
	elif [[ "$1" == 2.3.5 ]]; then node_version='14.17.5'
	elif [[ "$1" == 2.3.6 ]]; then node_version='14.17.6'
	elif [[ "$1" == 2.3.7 ]]; then node_version='14.17.6'
	elif [[ "$1" == 2.4 ]]; then node_version='14.17.6'
	elif [[ "$1" == 2.5 ]]; then node_version='14.18.1'
	# Versions from 2.5.1 to 2.5.5 are unsupported because the Fibers version is missing binaries
	elif [[ "$1" == 2.5.6 ]]; then node_version='14.18.3'
	elif [[ "$1" == 2.5.7 ]]; then node_version='14.19.3'
	elif [[ "$1" == 2.5.8 ]]; then node_version='14.19.3'
	elif [[ "$1" == 2.6 ]]; then node_version='14.18.3'
	elif [[ "$1" == 2.6.1 ]]; then node_version='14.18.3'
	elif [[ "$1" == 2.7 ]]; then node_version='14.19.1'
	elif [[ "$1" == 2.7.1 ]]; then node_version='14.19.1'
	elif [[ "$1" == 2.7.2 ]]; then node_version='14.19.1'
	elif [[ "$1" == 2.7.3 ]]; then node_version='14.19.3'
	elif [[ "$1" == 2.8.0 ]]; then node_version='14.20.1'
	elif [[ "$1" == 2.8.1 ]]; then node_version='14.21.1'
	elif [[ "$1" == 2.9.0 ]]; then node_version='14.21.1'
	elif [[ "$1" == 2.9.1 ]]; then node_version='14.21.2'
	elif [[ "$1" == 2.10.0 ]]; then node_version='14.21.2'
	elif [[ "$1" == 2.11.0 ]]; then node_version='14.21.3'
	elif [[ "$1" == 2.12 ]]; then node_version='14.21.3'
	elif [[ "$1" == 2.13 ]]; then node_version='14.21.4'
	elif [[ "$1" == 2.13.1 ]]; then node_version='14.21.4'
	elif [[ "$1" == 2.13.3 ]]; then node_version='14.21.4'
	elif [[ "$1" == 2.14 ]]; then node_version='14.21.4'
	elif [[ "$1" == 2.15 ]]; then node_version='14.21.4'
	elif [[ "$1" == 2.16 ]]; then node_version='14.21.4'
	elif [[ "$1" == 3.0.1 ]]; then node_version='20.15.1'
	elif [[ "$1" == 3.0.2 ]]; then node_version='20.15.1'
	elif [[ "$1" == 3.0.3 ]]; then node_version='20.17.0'
	elif [[ "$1" == 3.0.4 ]]; then node_version='20.18.0'
	elif [[ "$1" == 3.1 ]]; then node_version='22.11.0'
	elif [[ "$1" == 3.1.1 ]]; then node_version='22.13.0'
	fi # End of versions
}


# Use printf to get appropriate version string for comparison
get_version_string() {
	printf "%02d%02d%02d" $(echo "$1" | tr '.' ' ');
}
