#!/usr/bin/bash
PS3="Your choice: "
Green1="\033[32m"
Green2="\033[0m"

osCheck() {
	if [ -e /etc/redhat-release ]; then
		REDHAT=`cat /etc/redhat-release | awk '{print $1}'`
	else
		DEBIAN=`cat /etc/issue | awk '{print $1}'`
	fi

	if [ "$REDHAT" == "CentOS" -o "$REDHAT" == "Red" ]; then
		P_M=yum
	elif [ "$DEBIAN" == "Ubuntu" -o "$DEBIAN" == "ubuntu" ]; then
		P_M=apt-get
	else
		Operating system dose not support.
		exit 1
	fi
}

if [ $LOGNAME != root ]; then
	echo "Please use the root account operation."
	exit 1
fi

if ! which vmstat &>/dev/null; then
	echo "vmstat command not found, now the install."
	sleep 1
	osCheck
	$P_M install procps -y
	echo "------------------------------------------------------------------------"
fi

if ! which iostat &>/dev/null; then
	echo "iostat command is not found, now the install."
	sleep 1
	$P_M install sysstat -y
	echo "------------------------------------------------------------------------"
fi

while true
do
	select choice in cpu_load disk_load disk_use disk_inode mem_use tcp_status cpu_top10 mem_top10 traffic quit
	do
		case "$choice" in 
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
			tcp_status)
				echo "-----------------------------------------"
				COUNT=`ss -ant | awk '!/State/{status[$1]++}END{for(i in status)print i, status[i]}'`
				echo -e "TCP connection status: \n$COUNT"
				echo "-----------------------------------------"
				break
				;;
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
