#!/usr/bin/bash
read -p "Please input number: " num

while true
do
	if [[ "$num" =~ ^[0-9]+$ ]]; then
		break
	else
		read -p "请输入数字: " num	
	fi
done

read -p "Please input prefix: " prefix

while true
do
	if [ -n "$prefix" ]; then
		break
	else	
		read -p "请输入正确的prefix: " prefix
	fi
done

for i in `seq $num`
do
	user=$prefix$i
	useradd $user
	if [ $? -eq 0 ]; then
		echo "创建成功！"
	fi
done

	
