#!/usr/bin/bash
ip=www.baidu.com
if ping -c1 $ip &>/dev/null; then
	echo "$ip is up."
else
	echo "$ip is down."
fi
