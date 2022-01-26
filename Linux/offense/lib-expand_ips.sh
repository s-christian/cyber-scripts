#!/usr/bin/env bash


# *** Source other library functions ***

. ./lib-cecho.sh 2>/dev/null


#######################################
# Expand an IP CIDR notation or IP address range into a list of IP addresses,
# one per line. Utilizes `nmap` to generate the list, so the IP address range
# must be acceptable by Nmap.
#
# Globals:
#   None
# Arguments:
#   IP range, such as 192.168.1.0/24, 192.168.1.50-100, 192.168.*.5-10, etc.
# Outputs:
#   A list of IP addresses within the range, one per line
# Returns:
#   0 on success, 1 otherwise
########################################
expand_ips() {
	if [ $# -ne 1 ]; then
		cecho error "expand_ips usage: expand_ips <ip|ip_cidr|ip_range>"
		return 1
	fi
	
	local ip_range=$1

	local ip_list=$(nmap -n -sL ${ip_range} 2>/dev/null | awk '/Nmap scan report/{print $NF}')

	if [ -z "$ip_list" ]; then
		cecho error "expand_ips: Invalid IP/range"
		return 1
	fi

	echo "$ip_list"
}
