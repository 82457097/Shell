#!/usr/bin/bash

if [ $UID -ne 0 ]; then
	echo "你没有权限！"
	exit
fi

apt-get install httpd
