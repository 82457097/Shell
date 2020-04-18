#!/usr/bin/bash

PS3="Your choice is:"

select choice in disk_partition filesystem cpu_load mem_util quit
do
	case "$choice" in
		disk_partition)
			fdisk -l
			;;
		filesystem)
			df -h
			;;
		cpu_load)
			uptime
			;;
		mem_util)
			free -m
			;;
		quit)
			break
			;;
		*)
			echo "error!"
			exit
	esac
done

