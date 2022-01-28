#!/usr/bin/env bash


# *** Source other library functions ***

. ./lib-cecho.sh 2>/dev/null


#######################################
# Check if the given command exists and is executable.
#
# Globals:
#   None
# Arguments:
#   The binary/command to search the existence of
# Outputs:
#   Usage information on improper usage, otherwise none
# Returns:
#   0 if the binary/command exists, 1 otherwise
########################################
exists() {
	if [ $# -ne 1 ]; then
		cecho error "exists usage: exists <binary/command/executable>"
		return 1
	fi
	
	local search="$1"

	test -x "$(command -v "$search")" &>/dev/null
}
