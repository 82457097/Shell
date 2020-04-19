#!/usr/bin/bash
function ProcBar() {
	rate=0
	str=""
	arr=("|" "/" "-" "\\")
	while [ $rate -le 100 ]
	do
		index=rate%4
		printf "[%-100s] [%d%%] [%s]\r" "$str" "$rate" "${arr[$index]}"
		str+='#'
		let rate++
		sleep 0.1
	done
	printf "\n"
}
ProcBar


