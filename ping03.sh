#!/usr/bin/bash
read -p "请输入IP:" ip

ping -c1 $ip &>/dev/null
if [ $? -eq 0 ]; then
	echo "$ip is up."
else
	echo "$ip is down."
fi
