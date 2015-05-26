#!/bin/bash

HIGHALLOC_ALLOC_RATE=16
MB_PER_SEC=$HIGHALLOC_ALLOC_RATE
HIGHALLOC_DEBUGFS_DIR=/sys/kernel/debug/highalloc-test

setup_highalloc()
{
	local HIGHALLOC_ORDER=$1
	local HIGHALLOC_GFPFLAGS=$2
	local HIGHALLOC_PERCENTAGE=$3

	PAGESIZE=`getconf PAGESIZE`
	MEMTOTAL_BYTES=`run_target_cmd "free -b" | grep Mem: | awk '{print $2}'`

	BYTES_PER_MS=$(($MB_PER_SEC*1048576/1000))
	ALLOC_PAGESIZE=$(($PAGESIZE*(1<<$HIGHALLOC_ORDER)))
	MS_DELAY=$(($ALLOC_PAGESIZE/$BYTES_PER_MS))

	HIGHALLOC_PAGES=$((1 << $HIGHALLOC_ORDER))
	HIGHALLOC_SIZE=$(($HIGHALLOC_PAGES * $PAGESIZE))
	HIGHALLOC_COUNT=$(($MEMTOTAL_BYTES * $HIGHALLOC_PERCENTAGE/$HIGHALLOC_SIZE/100))

	echo "Pagesize:         $PAGESIZE"
	echo "Memtotal:		$MEMTOTAL_BYTES"
	echo "Huge Pagesize:    $HUGE_PAGESIZE"
	echo "HugeTLB Order:    $HUGETLB_ORDER"
	echo "High alloc count: $HIGHALLOC_COUNT"
	echo "Ms delay: $MS_DELAY"

	run_target_cmd "'sudo bash -c \"echo $MS_DELAY > $HIGHALLOC_DEBUGFS_DIR/msdelay\"'"
	run_target_cmd "'sudo bash -c \"echo $HIGHALLOC_COUNT > $HIGHALLOC_DEBUGFS_DIR/count\"'"
	run_target_cmd "'sudo bash -c \"echo $HIGHALLOC_GFPFLAGS > $HIGHALLOC_DEBUGFS_DIR/gfp_flags\"'"
	run_target_cmd "'sudo bash -c \"echo $HIGHALLOC_ORDER > $HIGHALLOC_DEBUGFS_DIR/order\"'"
}

run_highalloc()
{
	local OUTPUT=$RESULT_LOG

	run_target_cmd "'sudo dmesg -c'" >> $OUTPUT

	local STARTALLOC=`date +%s`
	run_target_cmd "'sudo bash -c \"echo 1 > $HIGHALLOC_DEBUGFS_DIR/runtest\"'"
	run_target_cmd "dmesg" | grep "highalloc_test" | awk '{print substr($0, index($0, ":") + 2)}' | tee /tmp/highalloc.out

	run_target_cmd "'sudo dmesg -c > /dev/null'"
	#stap -DSTAP_OVERRIDE_STUCK_CONTEXT -g /tmp/highalloc.stp | tee /tmp/highalloc.out
	local ENDALLOC=`date +%s`
	sleep 5

	echo >> $OUTPUT
	echo HighAlloc Under Highly Fragmented Memory Test Results >> $OUTPUT
	echo ---------------------------------------- >> $OUTPUT
	cat /tmp/highalloc.out >> $OUTPUT
	grep -A 15 "Test completed" /tmp/highalloc.out
	echo Duration alloctest pass 1: $(($ENDALLOC-$STARTALLOC)) >> $OUTPUT

	run_target_cmd "sudo killall make"
	sleep 5
}
