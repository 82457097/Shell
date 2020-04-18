#!/usr/bin/bash

disk_use=`df -Th |grep '/$' |awk '{print $(NF-1)}' |awk -F"%" '{print $1}'`

if [ $disk_use -ge 9 ]; then
	echo "`date +%F-%H` disk: ${disk_use}%" |mail -s "disk warnning..." junbaba
fi
