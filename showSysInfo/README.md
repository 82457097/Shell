# 一、项目简介
该项目为shell脚本学习项目，整合了一些系统信息收集的操作，有CPU负载、磁盘负载、磁盘使用率、磁盘文件inode使用率、内存使用率、网络连接信息、CPU使用前十进程、内存消耗前十进程、网络流量等。
# 二、项目分析
## 1.系统和命令检测
为了使收集信息的指令能够正常使用，必须先对必要的命令进行可用检测。
```bash
#检测系统版本
OsCheck() {
	if [ -e /etc/redhat-release ]; then
		REDHAT=`cat /etc/redhat-release | awk '{print $1}'`
	else
		DEBIAN=`cat /etc/issue | awk '{print $1}'`
	fi
	
	#确定 P_M 变量的值，为了后续的下载指令
	if [ "$REDHAT" == "CentOS" -o "$REDHAT" == "Red" ]; then
		P_M=yum
	elif [ "$DEBIAN" == "Ubuntu" -o "$DEBIAN" == "ubuntu" ]; then
		P_M=apt-get
	else
		Operating system dose not support.
		exit 1
	fi
}

#检测是否有root权限
if [ $LOGNAME != root ]; then
	echo "Please use the root account operation."
	exit 1
fi

#检测vmstat命令是否可用，不可用则下载
if ! which vmstat &>/dev/null; then
	echo "vmstat command not found, now the install."
	sleep 1
	OsCheck
	$P_M install procps -y
	echo "------------------------------------------------------------------------"
fi

#检测iostat命令是否可用，不可用则下载
if ! which iostat &>/dev/null; then
	echo "iostat command is not found, now the install."
	sleep 1
	$P_M install sysstat -y
	echo "------------------------------------------------------------------------"
fi
```

## 2.建立工作主循环
使用select自动生成操作选项列表，然后再将指定操作插入case。
```bash
while true
do
	select choice in cpu_load disk_load disk_use disk_inode mem_use tcp_status cpu_top10 mem_top10 traffic quit
	do
		case "$choice" in 
		#To do。。。
		#To do。。。
		#To do。。。
			quit)
				exit 0
				;;
			*)
				echo "---------------------------------------"
				echo "Please input corret number."
				echo "---------------------------------------"
				break
				;;
		esac
	done
done		
```
## 3.CPU负载
$Green1 和 $Green2 位颜色定义宏Green1="\033[32m" Green2="\033[0m"。该操作一共取三次结果，间隔一秒，分别取vmstat第3行（if(NR==3)）第13-16列结果输出。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419193943439.png)
```bash
cpu_load)
		echo "---------------------------------------"
		i=1
		while [[ $i -le 3 ]]; do
			echo -e "$Green1 参考值${i} $Green2"
			UTIL=`vmstat | awk '{if(NR==3)print 100-$15"%"}'`
			USER=`vmstat | awk '{if(NR==3)print $13"%"}'`
			SYS=`vmstat | awk '{if(NR==3)print $14"%"}'`
			IOWAIT=`vmstat | awk '{if(NR==3)print $16"%"}'`
			echo "Util: $UTIL"
			echo "USER: $USER"
			echo "System use: $SYS"
			echo "I/O wait: $IOWAIT"
			let i++
			sleep 1
		done
		break
		;;
```
## 4.磁盘负载
同样取三次结果，//中间为正则表达式，表示取以v或者s开头的行，然后OFS给定分割符号，分别打印iostat显示的信息。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419210107220.png)![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419210355239.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NDgxNjczMg==,size_16,color_FFFFFF,t_70)
```bash
disk_load)
		echo"----------------------------------------"
		i=1
		while [[ $i -le 3 ]]; do
			echo -e "$Green1 参考值${i} $Green2"
			UTIL=`iostat -x -k | awk '/^[v|s]/{OFS=": ";print $1,$NF"%"}'`
			READ=`iostat -x -k | awk '/^[v|s]/{OFS=": ";print $1,$6"KB"}'`
			WRITE=`iostat -x -k | awk '/^[v|s]/{OFS=": ";print $1,$7"KB"}'`
			IOWAIT=`vmstat | awk '{if(NR==3)print $16"%"}'`
			echo -e "UTIL: $UTIL"
			echo -e "Read/s:$READ"
			echo -e "I/O wait: $IOWAIT"
			echo -e "Write/s: $WRITE"
			i=$(($i+1))
			sleep 1
		done
		break
		;;
```
## 5.磁盘使用率
取fdisk -l 命令，正则表达式表示以Disk开头，bytes结束的行，并且带有/dev目录的行。输出第二列，格式输出第三列。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419211549920.png)![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419211809360.png)
```bash
disk_use)
		DISK_LOG=/tmp/disk_use.tmp
		DISK_TOTAL=`fdisk -l | awk '/^Disk.*bytes/&&/\/dev/{printf $2" ";printf "%d",$3;print "GB"}'`
		USE_RATE=`df -h | awk '/^\/dev/{print int($5)}'`
		for i in $USE_RATE; do
			if [ $i -gt 90 ]; then
				PART=`df -h | awk '{if(int($5)=='''$i''')print $6}'`
				echo "$PART = ${i}%" >> $DISK_LOG
			fi
		done
		echo "--------------------------------------"
		echo -e "Disk total:${DISK_TOTAL}"
		if [ -f $DISK_LOG ]; then
			echo "----------------------------------------"
			cat $DISK_LOG
			echo "----------------------------------------"
			rm -f $DISK_LOG
		else
			echo "----------------------------------------"
			echo "Disk use rate no than 90% of the partition."
			echo "----------------------------------------"
		fi
		break
		;;
```
## 6.磁盘文件inode使用率
使用df -i命令，查看inode使用率，正则表达式表示已/dev目录开头的行，取第五列的数值给INODE_USE。i == INODE_USE，如果i大于等于90的话，就取df -h 匹配i的第六列，并将信息写入文件inode_use.tmp。
![在这里插入图片描述](https://img-blog.csdnimg.cn/2020041921281760.png)![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419212943787.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NDgxNjczMg==,size_16,color_FFFFFF,t_70)
```bash
disk_inode)
		INODE_LOG=/tmp/inode_use.tmp
		INODE_USE=`df -i | awk '/^\/dev/{print int($5)}'`
		for i in $INODE_USE; do
			if [ $i -gt 90 ]; then
				PART=`df -h| awk '{if(int($5)=='''$i''')print $6}'`
				echo "$PART= ${i}%" >> $INODE_LOG
			fi
		done
		if [ -f $INODE_LOG ]; then
			echo "---------------------------------------"
			cat $INDOE_LOG
			rm -f $INODE_LOG
		else
			echo "---------------------------------------"
			echo "Indoe use rate no than 90% of the -artition."
			echo "Inode use rate no than 90% of the partition."
			echo "---------------------------------------"
		fi
		break
		;;
```
## 7.内存使用率
取free -m 命令的第二行，分别格式输出第2、3、4、6列除以1024的值。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419213758144.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/2020041921365011.png)
```bash
mem_use)
		echo "-----------------------------------------"
		MEM_TOTAL=`free -m | awk '{if(NR==2)printf "%0.1f",$2/1024}END{print "G"}'`
		USE=`free -m | awk '{if(NR==2)printf "%0.1f",$3/1024}END{print "G"}'`
		FREE=`free -m | awk '{if(NR==2)printf "%0.1f",$4/1024}END{print "G"}'`
		CACHE=`free -m | awk '{if(NR==2)printf "%0.1f",$6/1024}END{print "G"}'`
		echo -e "Total: $MEM_TOTAL"
		echo -e "Use: $USE"
		echo -e "Free: $FREE"
		echo -e "Cache: $CACHE"
		echo "-----------------------------------------"
		break
		;;
```

## 8.网络连接信息
取netstat -ant 最后一列，并且建立一个key-value数组state数组来计数。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419214314364.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NDgxNjczMg==,size_16,color_FFFFFF,t_70)
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419214034488.png)
```bash
tcp_status)
		echo "-----------------------------------------"
		COUNT=`ss -ant | awk '!/State/{status[$1]++}END{for(i in status)print i, status[i]}'`
		echo -e "TCP connection status: \n$COUNT"
		echo "-----------------------------------------"
		break
		;;
```
## 9.CPU使用前十进程
取ps aux命令的第三列，并与0.1比较，当大于时，输出该行3和11-16信息，并且在后面打印PID，并且排序取前十行。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419215148782.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NDgxNjczMg==,size_16,color_FFFFFF,t_70)
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419215242928.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NDgxNjczMg==,size_16,color_FFFFFF,t_70)
```bash
cpu_top10)
		echo "-----------------------------------------"
		CPU_LOG=/tmp/cpu_top.tmp
		i=1
		while [[ $i -le 3 ]]; do
			ps aux | awk '{if($3>0.1)print " CPU: "$3"% --> ", $11, $12, $13, $14, $15, $16, "(PID:"$2")" | "sort -k2 -nr | head -n 10"}' > $CPU_LOG
			#ps aux | awk '{if($3>0.1){{printf "PID: "$2" CPU: "$3"% -->"}for(i=11;i<=NF;i++)if(i==NF)printf $i"\n";else printf $i}}' | sort -k4 -nr | head -10 > $CPU_LOG
			if [[ -n `cat $CPU_LOG` ]]; then
				echo -e "$Green1 参考值 $Green2"
				cat $CPU_LOG
				> $CPU_LOG
			else
				echo "No process using the CPU."
				break
			fi
			let i++
			sleep 1
		done
		echo "-----------------------------------------"
		break
		;;
```

## 10.内存消耗前十进程
与上面那个差不多，只不过这事查看内存，自然取第四列参数大于0.1的，并且排序取前十行。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419215549338.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NDgxNjczMg==,size_16,color_FFFFFF,t_70)
![在这里插入图片描述](https://img-blog.csdnimg.cn/2020041921544858.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NDgxNjczMg==,size_16,color_FFFFFF,t_70)
```bash
mem_top10)
		echo "-----------------------------------------"
		MEM_LOG=/tmp/mem_log.tmp
		i=1
		while [[ $i -le 3 ]]; do
			ps aux | awk '{if($4>0.1)print " Memory: "$4"% --> ", $11, $12, $13, $14, $15, $16, "(PID:"$2")" | "sort -k2 -nr | head -n 10"}' > $MEM_LOG
			#ps aux | awk '{if($4>0.1){{printf "PID: "$2" Memory: "$4"% -->"}for(i=11;i<=NF;i++)if(i==NF)printf $i"\n";else printf $i}}' | sort -k4 -nr | head -10 > $MEM_LOG
			if [[ -n `cat $MEM_LOG` ]]; then
				echo -e "$Green1 参考值 $Green2"
				cat $MEM_LOG
				> $MEM_LOG
			else
				echo "No process using the Memory."
				break
			fi
			let i++
			sleep 1
			done
			echo "-----------------------------------------"
		break
		;;
```
## 11.网络流量
先要求用户输入需要查看的网卡名称，并赋值给变量eth，再在ifconfig命令里查看是否有该网卡，没有要求重新输入。然后检测三遍接收和上传总量，并且让前后的值分别相减，得出单位时间内的接收和上传带宽。单位是MB/s，所以会用得到的值/1024/128。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419220608644.png)
没有下载或者上传东西，所以显示为0。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200419220523658.png)
```bash
traffic)
		while true; do
			read -p "Please enter the network card name(eth[0-9] or em[0-9]): " eth
			if [ `ifconfig | grep -c "\<$eth\>"` -eq 1 ]; then
				break
			else
				echo "Input formate error or Don't have the card name, please input again."
			fi
		done
		echo "---------------------------------------"
		echo -e "In -------- Out"
		i=1
		while [[ $i -le 3 ]]; do
			OLD_IN=`ifconfig $eth | awk -F'[: ]+' '/bytes/{if(NR==8)print $4;else if(NR==5)print $6}'`
			OLD_OUT=`ifconfig $eth | awk -F'[: ]+' '/bytes/{if(NR==8)print $9;else if(NR==7)print $6}'`
			sleep 1
			NEW_IN=`ifconfig $eth | awk -F'[: ]+' '/bytes/{if(NR==8)print $4;else if(NR==5)print $6}'`
			NEW_OUT=`ifconfig $eth | awk -F'[: ]+' '/bytes/{if(NR==8)print $9;else if(NR==7)print $6}'`
			IN=`awk 'BEGIN{printf "%.1f\n", '$((${NEW_IN}-${OLD_IN}))'/1024/128}'`
			OUT=`awk 'BEGIN{printf "%.1f\n", '$((${NEW_OUT}-${OLD_OUT}))'/1024/128}'`
			echo "${IN}MB/s ${OUT}MB/s"
			i=$(($i+1))
			sleep 1
		done
		echo "---------------------------------------"
		break
		;;
```
# 三、项目总结
该项目将大部分系统信息统计结果进行了剪裁处理，展示给用户直观的了解设备实时状态信息。做这个项目的目的是为了巩固shell脚本的知识和学习一些Linux命令的使用。该项目写的比较乱，后面会将各部分操作用函数封装起来，这样shell程序将会更加简洁易读。
