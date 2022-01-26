#!/usr/bin/env bash

# *** Source library functions ***

. ./lib-cecho.sh      2>/dev/null
. ./lib-expand_ips.sh 2>/dev/null
. ./lib-root_check.sh 2>/dev/null


# *** Configuration variables ***

DEFAULT_USER='zathras'
DEFAULT_PASSWORD='password1!'

BANNER="${PURPLE}"' ____                      _            ____                                  
|  _ \ ___ _ __ ___   ___ | |_ ___     / ___| _ __  _ __ __ _ _   _  ___ _ __ 
| |_) / _ \ '\''_ ` _ \ / _ \| __/ _ \____\___ \| '\''_ \| '\''__/ _` | | | |/ _ \ '\''__|
|  _ <  __/ | | | | | (_) | ||  __/_____|__) | |_) | | | (_| | |_| |  __/ |   
|_| \_\___|_| |_| |_|\___/ \__\___|    |____/| .__/|_|  \__,_|\__, |\___|_|   
      '"${COLOR_OFF}${CYAN}"'By: Christian'"${COLOR_OFF}${PURPLE}"'                          |_|              |___/'"${COLOR_OFF}
"


# *** Helper functions ***

print_help() {
	echo -e "${CYAN}Remote Sprayer${COLOR_OFF} - ${YELLOW}Automatic persistence on targets via SSH password spraying${COLOR_OFF}"
	echo -e "    ${GREEN}Usage: $0 [-u|--user|-U|--users] [-p|--password|-P|--passwords] <target>${COLOR_OFF}"
	echo -e "           ${GREEN}$0 [-u|--user|-U|--users] [-p|--password|-P|--passwords] {-T|--targets}${COLOR_OFF}"
	echo
	echo -e "${BOLD_WHITE}TARGET(S):${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}<target>:${COLOR_OFF} A valid hostname, IP address, or IP address range that can be understood by Nmap"
	echo -e "    ${BOLD_WHITE}-T|--targets <targets_file>:${COLOR_OFF} Path to a file containing targets, one target per line"
	echo -e "${BOLD_WHITE}USER(S):${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-p|--password <password>:${COLOR_OFF} A password to authenticate with for each user logon attempt ${BOLD_WHITE}(default: $DEFAULT_PASSWORD)${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-P|--passwords <passwords_file>:${COLOR_OFF} Path to a file containing passwords, one password per line"
	echo -e "${BOLD_WHITE}PASSWORD(S):${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-u|--user <user>:${COLOR_OFF} A user to authenticate as on each target ${BOLD_WHITE}(default: $DEFAULT_USER)${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-U|--users <users_file>:${COLOR_OFF} Path to a file containing users, one user per line"
	echo -e "${BOLD_WHITE}SWITCHES:${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-q|--quiet:${COLOR_OFF} Don't print the banner ASCII art"
	echo -e "${BOLD_WHITE}HELP:${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-h|--help:${COLOR_OFF} Print this usage information"
}


# *** Main ***

# Command-line argument parsing
# Reference: https://stackoverflow.com/a/29754866
getopt --test > /dev/null
if [ $? -ne 4 ]; then
	cecho error "Your getopt version is out of date according to \`getopt --test\`. Exiting."
	exit 1
fi

# "a"  = enable the flag (boolean, true)
# "a:" = requires a value
OPTIONS=T:u:U:p:P:qh
LONGOPTS=targets:,user:,users:,password:,passwords:,quiet,help

# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [ $? -ne 0 ]; then
	# e.g. return value is 1
	# then getopt has complained about wrong arguments to stdout
	print_help
	exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

target=""
target_file=""
user="$DEFAULT_USER"
users_file=""
password="$DEFAULT_PASSWORD"
passwords_file=""
print_banner=true

# now enjoy the options in order and nicely split until we see --
while true; do
	case "$1" in
#		-t|--target)
#			target="$2"
#			shift 2
#			;;
		-T|--targets)
			targets_file="$2"
			shift 2
			;;
		-u|--user)
			user="$2"
			shift 2
			;;
		-U|--users)
			users_file="$2"
			shift 2
			;;
		-p|--password)
			password="$2"
			shift 2
			;;
		-P|--passwords)
			passwords_file="$2"
			shift 2
			;;
		-q|--quiet)
			print_banner=false
			shift
			;;
		-h|--help)
			print_help
			exit 0
			;;
		--)
			shift
			break
			;;
		*)
			cecho error "Command-line argument parsing programming error"
			exit 3
			;;
	esac
done

# Handle non-option arguments (starts at $1 like normal)
target="$1"

# Ensure all mandatory arguments are provided
if [ -z "$target" ] && [ -z "$targets_file"]; then
	cecho error "Must provide a target or targets file"
	invalid_usage=true
fi

if [ -z "$user" ] && [ -z "$users_file" ]; then
	cecho error "Must provide a user or users file"
	invalid_usage=true
fi

if [ -z "$password" ] && [ -z "$passwords_file" ]; then
	cecho error "Must provide a password or passwords file"
	invalid_usage=true
fi

if [ "$invalid_usage" = true ]; then
	print_help
	exit 1
fi


[ $print_banner = true ] && echo -e "$BANNER"

target_list=""
user_list=""
password_list=""

if [ -n "$target" ]; then
	target_list=$(expand_ips "$target")
	if [ $? -ne 0 ]; then
		cecho error "Nmap is unable to parse '$target' as a valid target or target range"
		exit 1
	fi
else # at this point targets_file must be defined
	if [ ! -f "$targets_file" ]; then
		cecho error "Targets file '$targets_file' does not exist"
		exit 1
	fi

	if [ ! -r "$targets_file" ]; then
		cecho error "Unable to read targets file '$targets_file'"
		exit 1
	fi

	target_list=$(cat "$targets_file")
fi

if [ -n "$user" ]; then
	user_list="$user"
else # at this point users_file must be defined
	if [ ! -f "$users_file" ]; then
		cecho error "Users file '$users_file' does not exist"
		exit 1
	fi

	if [ ! -r "$users_file" ]; then
		cecho error "Unable to read users file '$users_file'"
		exit 1
	fi

	user_list=$(cat "$users_file")
fi

if [ -n "$password" ]; then
	password_list="$password"
else # at this point passwords_file must be defined
	if [ ! -f "$passwords_file" ]; then
		cecho error "Passwords file '$passwords_file' does not exist"
		exit 1
	fi

	if [ ! -r "$passwords_file" ]; then
		cecho error "Unable to read passwords file '$passwords_file'"
		exit 1
	fi

	password_list=$(cat "$passwords_file")
fi

cecho info "Attempting logins..."
for t in $target_list; do
	for u in $user_list; do
		for p in $password_list; do
			echo "$u:$p @ $t"
		done
	done
done


#echo "target: '$target', targets_file: '$targets_file', user: '$user', users_file: '$users_file', password: '$password', passwords_file: '$passwords_file', in: '$1'"


