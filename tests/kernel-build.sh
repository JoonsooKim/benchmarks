#!/bin/bash
source lib/target-system.sh
source lib/report.sh
source lib/pressure.sh
source lib/highalloc.sh

SEQ=$1
KERNEL=$2
ANALYSIS=$3
BENCH_TYPE=$4

MEM=1024

if [ "$BENCH_TYPE" == "cma-zram" ]; then
	CMA=1
	ZRAM_SIZE=512M

elif [ "$BENCH_TYPE" == "cma-none" ]; then
	CMA=1

elif [ "$BENCH_TYPE" == "none-zram" ]; then
	ZRAM_SIZE=512M

elif [ "$BENCH_TYPE" == "none-none" ]; then
	echo "" > /dev/null;

else
	exit;
fi


#### Start benchmark ####
DIR=result-kernel-build-$BENCH_TYPE

setup_report "$KERNEL" "$MEM" "$SEQ" "$DIR" "$ANALYSIS"
clear_result_log
if [ "$TRACEPOINT_ON" == "1" ]; then
	PARAM="trace_buf_size=4M trace_event=compaction:*"
	MEM=$(($MEM+32))
fi
if [ "$CMA" == "1" ]; then
	PARAM="cma_test_areas=on " $PARAM
fi

setup_target "$KERNEL" "$MEM" "$PARAM"
launch_target
wait_target

setup_swap_zram $ZRAM_SIZE
get_report

get_report
run_target_cmd "\"(cd /home/js1304/test-work/build-test/linux-3.0; make clean &> /dev/null; ) \"" 1
run_target_cmd "\"(cd /home/js1304/test-work/build-test/linux-3.0; time make -j16 &> /dev/null; ) \"" &>> $RESULT_LOG
get_report

shutdown_target
