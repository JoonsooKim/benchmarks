#!/bin/bash
source lib/target-system.sh
source lib/report.sh
source lib/pressure.sh
source lib/options.sh
source lib/cma.sh

SEQ=$1
KERNEL=$2
ANALYSIS=$3
BENCH_TYPE=$4
OPTIONS=$5

MEM=1024

if [ "$BENCH_TYPE" == "hard" ]; then
	CMA_AREA="cma-0"

	# 256 MB
	NR_ALLOCS=16
	NR_PAGES=4096
	SHOULD_SUCCESS_ALL=1

elif [ "$BENCH_TYPE" == "normal" ]; then
	CMA_AREA="cma-0"

	# 120 MB
	NR_ALLOCS=30
	NR_PAGES=1024

elif [ "$BENCH_TYPE" == "easy" ]; then
	CMA_AREA="cma-0"

	# 20 MB
	NR_ALLOCS=10
	NR_PAGES=512

else
	exit;
fi

run_cmaalloc()
{
	local i
	local NR_ALLOCS=$1
	local NR_PAGES=$2
	local SHOULD_SUCCESS_ALL=$3

	get_report
	for i in `seq 1 $NR_ALLOCS`; do
		alloc_cma $NR_PAGES
		sleep 3
	done;

	if [ "$SHOULD_SUCCESS_ALL" == "1" ]; then
		while true; do
			local NR_SUCCESS=`get_success_cmaalloc`

			if [ "$NR_SUCCESS" == "$NR_ALLOCS" ]; then
				break;
			fi

			alloc_cma $NR_PAGES
			sleep 3
		done
	fi
	get_report

	for i in `seq 1 $NR_ALLOCS`; do
		free_cma $NR_PAGES
	done;

	get_report
}

#### Start benchmark ####
setup_cma $CMA_AREA

if [ "$OPTIONS" != "" ]; then
	ZRAM_SIZE=`get_value "$OPTIONS" ZRAM_SIZE`
	BACKGROUND_BUILD_THREADS=`get_value "$OPTIONS" BACKGROUND_BUILD_THREADS`
fi

if [ "$ZRAM_SIZE" == "" ]; then
	ZRAM_SIZE=0
fi
if [ "$BACKGROUND_BUILD_THREADS" == "" ]; then
	BACKGROUND_BUILD_THREADS=0
fi

DIR=result-cma-$BENCH_TYPE-$BACKGROUND_BUILD_THREADS-$ZRAM_SIZE

setup_report "$KERNEL" "$MEM" "$SEQ" "$DIR" "$ANALYSIS"
clear_result_log
if [ "$TRACEPOINT_ON" == "1" ]; then
	PARAM="trace_buf_size=4M trace_event=compaction:*"
	MEM=$(($MEM+32))
fi

PARAM="cma_test_areas=$BENCH_TYPE " $PARAM

setup_target "$KERNEL" "$MEM" "$PARAM"
launch_target
wait_target

setup_swap_zram $ZRAM_SIZE

setup_build_pressure $BACKGROUND_BUILD_THREADS

run_cmaalloc $NR_ALLOCS $NR_PAGES $SHOULD_SUCCESS_ALL
get_dmesg

shutdown_target
