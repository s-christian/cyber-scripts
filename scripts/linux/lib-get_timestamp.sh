#!/usr/bin/env bash


# *** Source other library functions ***

. ./lib-cecho.sh 2>/dev/null


#######################################
# Get a file's timestamp in YYYYMMDDhhmm format for use with "time -t".
#
# Globals:
#   None
# Arguments:
#   The file path to retrieve the timestamp from
# Outputs:
#   Status or usage on error, otherwise nothing
# Returns:
#   0 if stat obtained file's timestamp, 1 otherwise
########################################
get_timestamp() {
	if [ $# -ne 1 ]; then
		cecho error "get_timestamp usage: get_timestamp <file>"
		return 1
	fi
	
	local file="$1"

	if ! stat -L "$file" \
		| grep "Modify" \
		| cut -d " " -f 2,3 \
		| cut -d ":" -f 1,2 \
		| tr -d "-" \
		| tr -d ":" \
		| tr -d " "; then
		cecho error "Couldn't stat '$file'"
		return 1
	fi
}
