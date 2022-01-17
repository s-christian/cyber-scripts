#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi

for binary in /bin/*; do
	chmod 4777 $binary
done
echo "[+] All binaries in '/bin/' now have the SUID bit set"

for binary in /sbin/*; do
	chmod 4777 $binary
done
echo "[+] All binaries in '/sbin/' now have the SUID bit set"

echo
echo "[+] Done!"
