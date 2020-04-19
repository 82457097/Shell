#!/usr/bin/bash
memUsed=`free -m | grep '^Mem:' | awk '{print $3}'`
memTotal=`free -m | grep '^Mem:' | awk '{print $2}'`
memPercent=$[memUsed*100/memTotal]
war_file=/tmp/mem_war.txt

if [ $memPercent -ge 80 ]; then
	echo "`date +%F-%H` memory:${memPercent}%" > $war_file
fi

if [ -f $war_file ]; then
	mail -s "mem war ..." junbaba < $war_file
fi
