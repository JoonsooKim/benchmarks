#!/bin/bash
source lib/target-system.sh
source lib/report.sh
source lib/pressure.sh

SEQ=$1
KERNEL=$2
ANALYSIS=$3
BENCH_TYPE=zram
BUILD_THREADS=12

MEM=512
ZRAM_SIZE=512M

#### Start benchmark ####
DIR=result-fragmentation-$BENCH_TYPE

setup_report "$KERNEL" "$MEM" "$SEQ" "$DIR" "$ANALYSIS"
clear_result_log
if [ "$TRACEPOINT_ON" == "1" ]; then
	PARAM="trace_buf_size=4M trace_event=kmem:mm_page_alloc_extfrag"
	MEM=$(($MEM+32))
fi
PARAM="page_owner=on "$PARAM

setup_target "$KERNEL" "$MEM" "$PARAM"
launch_target
wait_target

get_report
setup_swap_zram $ZRAM_SIZE

get_report
run_target_cmd "\"(cd /home/js1304/test-work/build-test/linux-3.0; make clean; make -j$BUILD_THREADS ) \"" 1
get_report
get_dmesg

shutdown_target
