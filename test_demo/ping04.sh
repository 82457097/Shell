#!/usr/bin/bash
#如果用户没有加参数
if [ $# -eq 0 ]; then
	echo "usage: `basename $0` filename"
	exit
fi

#如果文件参数 文件格式不正确
if [ ! -f $1 ]; then
	echo "`basename $1` is error file!"
	exit
fi

#循环文件 给ip赋值并执行操作
for ip in `cat $1`
do
	ping -c1 $ip &>/dev/null
	if [ $? -eq 0 ]; then
		echo "$ip is up."
	else
		echo "$ip is down."
	fi
done
