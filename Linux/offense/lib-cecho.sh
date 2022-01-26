#!/usr/bin/env bash


# Colors
COLOR_OFF='\033[0m'
BOLD_WHITE='\033[1;37m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'


#######################################
# Log colored and status-prefixed text to the terminal depending on the
# user-provided log type.
#
# Globals:
#   All above colors
# Arguments:
#   Log type, one of "task", "error", "warning", "info", "log", or "debug"
#   Log message, the message to be printed to the terminal
# Outputs:
#   Colored and status-prefixed text otherwise, or usage on error
# Returns:
#   0 if cecho usage was correct, 1 otherwise
########################################
cecho() {
	local cecho_usage="${RED}[!] cecho usage: cecho <task|error|warning|info|log|debug|done> <\"log_message\">${COLOR_OFF}"

	if [ $# -ne 2 ]; then
		echo -e "$cecho_usage"
		return 1
	fi

	local log_type=$1
	local log_message=$2

	case $log_type in
		"task")
			echo
			echo -e "${BOLD_WHITE}[+] --- ${log_message}${COLOR_OFF}"
			;;
		"error")
			echo -e "${RED}[!] ${log_message}${COLOR_OFF}" >&2 # print to STDERR
			;;
		"warning")
			echo -e "${YELLOW}[-] ${log_message}${COLOR_OFF}"
			;;
		"info")
			echo -e "${CYAN}[*] ${log_message}${COLOR_OFF}"
			;;
		"log")
			echo -e "${BLUE}[^] ${log_message}${COLOR_OFF}"
			;;
		"debug")
			echo -e "${PURPLE}[?] ${log_message}${COLOR_OFF}"
			;;
		"done")
			echo -e "${GREEN}[=] ${log_message}${COLOR_OFF}"
			;;
		*)
			echo -e "$cecho_usage"
			return 1
			;;
	esac
}
