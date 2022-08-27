#!/usr/bin/env bash


# *** Source other library functions ***

. ./lib-cecho.sh 2>/dev/null


#######################################
# Set a file's timestamp (perform a "timestomp").
#
# Globals:
#   None
# Arguments:
#   The file path to set the timestamp on
# Outputs:
#   Status or usage on error, otherwise nothing
# Returns:
#   0 if file's timestamp was set, 1 otherwise
########################################
set_timestamp() {
	if [ $# -ne 2 ]; then
		cecho error "set_timestamp usage: set_timestamp <timestamp> <file>"
		return 1
	fi

	local timestamp="$1"
	local file="$2"

	if ! touch -t "$timestamp" "$file"; then
		cecho error "Couldn't modify timestamp for '$file'"
		return 1
	else
		cecho info "Modified timestamp for '$file'"
	fi
}
