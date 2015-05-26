#!/bin/bash

source lib/report.sh

FRAGALLOC_DEBUGFS_DIR=/sys/kernel/debug/fragalloc-test

setup_swap_zram()
{
	local ZRAM_SIZE=$1

	if [ "$ZRAM_SIZE" == "" ]; then
		return;
	fi
	run_target_cmd "'sudo bash -c \"swapoff -a\"'"

	run_target_cmd "'sudo bash -c \"echo 8 > /sys/block/zram0/max_comp_streams\"'"
	run_target_cmd "'sudo bash -c \"echo $ZRAM_SIZE > /sys/block/zram0/disksize\"'"
	run_target_cmd "'sudo bash -c \"mkswap /dev/zram0\"'"
	run_target_cmd "'sudo bash -c \"swapon /dev/zram0\"'"
}

setup_kernel_mem_pressure()
{
	local FRAGALLOC_FREE_PERCENTAGE=$1
	local FRAGALLOC_GFPFLAGS=$2

	if [ "$FRAGALLOC_FREE_PERCENTAGE" == "" ] || [ "$FRAGALLOC_FREE_PERCENTAGE" == "100" ]; then
		return;
	fi

	run_target_cmd "'sudo bash -c \"echo $FRAGALLOC_FREE_PERCENTAGE > $FRAGALLOC_DEBUGFS_DIR/free_percent\"'"
	run_target_cmd "'sudo bash -c \"echo $FRAGALLOC_GFPFLAGS > $FRAGALLOC_DEBUGFS_DIR/gfp_flags\"'"
	run_target_cmd "'sudo bash -c \"echo 1 > $FRAGALLOC_DEBUGFS_DIR/alloc\"'"
}

setup_anonymous_mem_pressure()
{
	local HOGGER_PRESSURE=$1
	local SPREAD_HOGGER_PRESSURE=$2

	if [ "$HOGGER_PRESSURE" == "" ]; then
		return;
	fi

	run_target_cmd "'sudo bash -c \"echo 100 > /proc/sys/vm/swappiness\"'"

	for j in `seq 1 $SPREAD_HOGGER_PRESSURE`; do
		local MEM_PRESSURE_DELAY=$(($j * 10))
		run_target_cmd "'sleep $MEM_PRESSURE_DELAY; sudo bash -c \"/home/js1304/bin/memory-hogger 100\"'" 1 &
	done

	run_target_cmd "\"(cd /home/js1304/test-work/build-test/linux-3.0; make clean; make -j4 ) \"" 1 &

	run_target_cmd "'sleep 120; sudo bash -c \"killall make\"; sudo bash -c \"killall cc\"'"

	local RUNNING_MEMORY_HOGGER=`get_hogger`
	local RUNNING_MEMORY_HOGGER=$(($RUNNING_MEMORY_HOGGER + 1))
	for j in `seq $RUNNING_MEMORY_HOGGER $HOGGER_PRESSURE`; do
		run_target_cmd "'sleep 1; sudo bash -c \"/home/js1304/bin/memory-hogger 100\"'" 1 &
	done

	if [ "$RUNNING_MEMORY_HOGGER" != "$HOGGER_PRESSURE" ]; then
		run_target_cmd "sleep 30"
	fi

	local RUNNING_MEMORY_HOGGER=`get_hogger`
	echo "Memory Hogger: $RUNNING_MEMORY_HOGGER"
}

setup_build_pressure()
{
	local BACKGROUND_BUILD_THREADS=$1

	if [ "$BACKGROUND_BUILD_THREADS" == "" ] || [ "$BACKGROUND_BUILD_THREADS" == "0" ]; then
		return;
	fi

	run_target_cmd "\"(cd /home/js1304/test-work/build-test/linux-3.0; make clean; make -j$BACKGROUND_BUILD_THREADS ) \"" 1 &

	sleep 30
}

