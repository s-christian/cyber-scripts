#!/usr/bin/env bash


# *** Source other library functions ***

. ./lib-cecho.sh 2>/dev/null


#######################################
# Check if the current script is being executed with root privileges. Exit if
# not.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Nothing on success, error message when not root
# Returns:
#   0 if root, 1 if not root
########################################
root_check() {
	if [ $EUID -ne 0 ]; then
		declare -f "cecho" > /dev/null \
			&& cecho error "Must run as root" \
			|| echo "[!] Must run as root"
		exit 1
	fi
}
