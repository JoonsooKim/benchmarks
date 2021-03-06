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
	RESULT_GRAPHDATA=$DIR/graphdata-$POSTFIX
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
	run_target_cmd "ps aux" | grep memory-hogger | awk -v GUEST_ID=$GUEST_ID '$1 ~ GUEST_ID { print $0 }' | wc -l | awk '{print $1}'
}

get_report()
{
	local OUTPUT_PAGE_TYPES=$RESULT_PAGE_TYPES.$RESULT_SEQ
	local OUTPUT_VMSTAT=$RESULT_VMSTAT.$RESULT_SEQ
	local OUTPUT_MEMINFO=$RESULT_MEMINFO.$RESULT_SEQ
	local OUTPUT_PAGETYPEINFO=$RESULT_PAGETYPEINFO.$RESULT_SEQ
	local OUTPUT_TRACEPOINT=$RESULT_TRACEPOINT.$RESULT_SEQ
	local OUTPUT_LOG=$RESULT_LOG
	local DROP_CACHE=$1

	RESULT_SEQ=$(($RESULT_SEQ+1))

	run_target_cmd "'sudo $BIN_PAGE_TYPES -L -N'" | tail -n +2 > $OUTPUT_PAGE_TYPES
	run_target_cmd "cat /proc/vmstat" | tail -n +2 > $OUTPUT_VMSTAT
	run_target_cmd "cat /proc/meminfo" | tail -n +2 > $OUTPUT_MEMINFO
	if [ "$DROP_CACHE" == "1" ]; then
		run_target_cmd "'sudo bash -c \"echo 3 > /proc/sys/vm/drop_caches\"'"
		run_target_cmd "'sudo bash -c \"echo 3 > /proc/sys/vm/drop_caches\"'"
	fi
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
}

compare_pagetypeinfo()
{
	local IDX=$1
	local SEQ=$(($IDX/2))

	cat $RESULT_PAGETYPEINFO".$IDX" | grep "Node 0, zone" | grep "DMA32" | awk -v idx=$SEQ '{ if ("u" in arr) { print "pb[" idx "]:DMA32:unmovable: " arr["u"] - strtonum($5); print "pb[" idx "]:DMA32:reclaimable: " arr["r"] - strtonum($6); print "pb[" idx "]:DMA32:movable: " arr["m"] - strtonum($7) } else { arr["u"] = strtonum($5); arr["r"] = strtonum($6); arr["m"] = strtonum($7); } }'
	cat $RESULT_PAGETYPEINFO".$IDX" | grep "Node 0, zone" | grep "Normal" | awk -v idx=$SEQ '{ if ("u" in arr) { print "pb[" idx "]:Normal:unmovable: " arr["u"] - strtonum($5); print "pb[" idx "]:Normal:reclaimable: " arr["r"] - strtonum($6); print "pb[" idx "]:Normal:movable: " arr["m"] - strtonum($7) } else { arr["u"] = strtonum($5); arr["r"] = strtonum($6); arr["m"] = strtonum($7); } }'
}
