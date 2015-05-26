#!/bin/bash

setup_report()
{
	local KERNEL=$1
	local MEM=$2
	local SEQ=$3
	local DIR=$4
	local ANALYSIS=$5

	TRACEPOINT_ON=0
	if [ "$ANALYSIS" == "1" ] || [ "$ANALYSIS" == "3" ]; then
		TRACEPOINT_ON=1
		DIR="trace-"$DIR
	fi

	PAGEOWNER_ON=0
	if [ "$ANALYSIS" == "2" ] || [ "$ANALYSIS" == "3" ]; then
		PAGEOWNER_ON=1
	fi

	mkdir -p $DIR

	POSTFIX=$KERNEL-$MEM-$SEQ.txt

	RESULT_LOG=$DIR/log-$POSTFIX
	RESULT_PAGE_TYPES=$DIR/page-types-$POSTFIX
	RESULT_VMSTAT=$DIR/vmstat-$POSTFIX
	RESULT_MEMINFO=$DIR/meminfo-$POSTFIX
	RESULT_PAGETYPEINFO=$DIR/pagetypeinfo-$POSTFIX
	RESULT_TRACEPOINT=$DIR/trace-$POSTFIX
	RESULT_SEQ=1
}

clear_result_log()
{
	echo "" > $RESULT_LOG
}

get_dmesg()
{
	run_target_cmd "'sudo dmesg -c'" >> $RESULT_LOG
}

get_hogger()
{
	run_target_cmd "ps aux" | grep memory-hogger | awk '$1 ~ /js1304/ { print $0 }' | wc -l | awk '{print $1}'
}

get_report()
{
	local OUTPUT_PAGE_TYPES=$RESULT_PAGE_TYPES.$RESULT_SEQ
	local OUTPUT_VMSTAT=$RESULT_VMSTAT.$RESULT_SEQ
	local OUTPUT_MEMINFO=$RESULT_MEMINFO.$RESULT_SEQ
	local OUTPUT_PAGETYPEINFO=$RESULT_PAGETYPEINFO.$RESULT_SEQ
	local OUTPUT_TRACEPOINT=$RESULT_TRACEPOINT.$RESULT_SEQ
	local OUTPUT_LOG=$RESULT_LOG

	RESULT_SEQ=$(($RESULT_SEQ+1))

	run_target_cmd "'sudo /home/js1304/bin/page-types -L -N'" | tail -n +2 > $OUTPUT_PAGE_TYPES
	run_target_cmd "cat /proc/vmstat" | tail -n +2 > $OUTPUT_VMSTAT
	run_target_cmd "cat /proc/meminfo" | tail -n +2 > $OUTPUT_MEMINFO
	run_target_cmd "cat /proc/pagetypeinfo" | tail -n +2 > $OUTPUT_PAGETYPEINFO

	local RUNNING_MEMORY_HOGGER=`get_hogger`
	echo "Memory Hogger: $RUNNING_MEMORY_HOGGER" >> $OUTPUT_LOG

	if [ "$TRACEPOINT_ON" == "1" ]; then
		run_target_cmd "'sudo cat /sys/kernel/debug/tracing/trace'" > $OUTPUT_TRACEPOINT
		run_target_cmd "'sudo bash -c \"echo > /sys/kernel/debug/tracing/trace\"'"
	fi
}

compare_report()
{
	cat $RESULT_LOG | grep "Success:" | awk '{print $2 " " $3}'
	cat $RESULT_LOG | tail -n 5 | grep "Hogger" | awk '{print $1 $2 " " $3}'
	cat $RESULT_VMSTAT".2" $RESULT_VMSTAT".3" | \
		awk '{ if ($1 in arr) { print $1 " " strtonum($2) - strtonum(arr[$1]) }; arr[$1] = $2; }' | \
		grep -e "compact" -e "migrate"
	cat $RESULT_MEMINFO".2" $RESULT_MEMINFO".3" | \
		awk '{ if ($1 in arr) { print $1 " " strtonum($2) - strtonum(arr[$1]) }; arr[$1] = $2; }' | \
		grep -e Mem -e Swap -e Active -e Inactive
	cat $RESULT_PAGETYPEINFO".2" | grep "Node 0, zone" | grep "DMA32" | awk '{print "pb:unmovable: " $5; print "pb:reclaimable: " $6; print "pb:movable: " $7}'
}
