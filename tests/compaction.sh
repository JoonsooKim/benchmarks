#!/bin/bash
source lib/target-system.sh
source lib/report.sh
source lib/pressure.sh
source lib/highalloc.sh

SEQ=$1
KERNEL=$2
ANALYSIS=$3
BENCH_TYPE=$4

MEM=512
HIGHALLOC_ORDER=3

GFP_HIGHUSER=0x200d2
GFP_HIGHUSER_MOVABLE=0x200da
HIGHALLOC_GFPFLAGS=$GFP_HIGHUSER_MOVABLE
HIGHALLOC_GFPFLAGS=$GFP_HIGHUSER


if [ "$BENCH_TYPE" == "hogger-only" ]; then
	HOGGER_PRESSURE=8
	SPREAD_HOGGER_PRESSURE=$(($HOGGER_PRESSURE - 2))

	BACKGROUND_BUILD_THREADS=0

	HIGHALLOC_PERCENTAGE=10

	ZRAM_SIZE=192M

elif [ "$BENCH_TYPE" == "hogger-build" ]; then
	HOGGER_PRESSURE=8
	SPREAD_HOGGER_PRESSURE=$(($HOGGER_PRESSURE - 2))

	BACKGROUND_BUILD_THREADS=1

	HIGHALLOC_PERCENTAGE=10

	ZRAM_SIZE=192M

elif [ "$BENCH_TYPE" == "mixed-frag-movable" ]; then
	HOGGER_PRESSURE=4
	SPREAD_HOGGER_PRESSURE=4

	FRAGALLOC_FREE_PERCENTAGE=75
	FRAGALLOC_GFPFLAGS=$GFP_HIGHUSER_MOVABLE

	BACKGROUND_BUILD_THREADS=1

	HIGHALLOC_PERCENTAGE=10

	ZRAM_SIZE=32M

elif [ "$BENCH_TYPE" == "mixed-frag-unmovable" ]; then
	HOGGER_PRESSURE=4
	SPREAD_HOGGER_PRESSURE=4

	FRAGALLOC_FREE_PERCENTAGE=75
	FRAGALLOC_GFPFLAGS=$GFP_HIGHUSER

	BACKGROUND_BUILD_THREADS=1

	HIGHALLOC_PERCENTAGE=10

	ZRAM_SIZE=32M

elif [ "$BENCH_TYPE" == "hogger-frag-movable" ]; then
	HOGGER_PRESSURE=4
	SPREAD_HOGGER_PRESSURE=0

	FRAGALLOC_FREE_PERCENTAGE=75
	FRAGALLOC_GFPFLAGS=$GFP_HIGHUSER_MOVABLE

	BACKGROUND_BUILD_THREADS=0

	HIGHALLOC_PERCENTAGE=10

	ZRAM_SIZE=32M

elif [ "$BENCH_TYPE" == "hogger-frag-unmovable" ]; then
	HOGGER_PRESSURE=4
	SPREAD_HOGGER_PRESSURE=0

	FRAGALLOC_FREE_PERCENTAGE=75
	FRAGALLOC_GFPFLAGS=$GFP_HIGHUSER

	BACKGROUND_BUILD_THREADS=0

	HIGHALLOC_PERCENTAGE=10

	ZRAM_SIZE=32M

elif [ "$BENCH_TYPE" == "build-frag-movable" ]; then
	FRAGALLOC_FREE_PERCENTAGE=75
	FRAGALLOC_GFPFLAGS=$GFP_HIGHUSER_MOVABLE

	BACKGROUND_BUILD_THREADS=8

	HIGHALLOC_PERCENTAGE=10

	ZRAM_SIZE=32M

elif [ "$BENCH_TYPE" == "build-frag-unmovable" ]; then
	FRAGALLOC_FREE_PERCENTAGE=75
	FRAGALLOC_GFPFLAGS=$GFP_HIGHUSER

	BACKGROUND_BUILD_THREADS=8

	HIGHALLOC_PERCENTAGE=10

	ZRAM_SIZE=32M

else
	exit;
fi




#### Start benchmark ####
DIR=result-compaction-$BENCH_TYPE

setup_report "$KERNEL" "$MEM" "$SEQ" "$DIR" "$ANALYSIS"
clear_result_log
if [ "$TRACEPOINT_ON" == "1" ]; then
	PARAM="trace_buf_size=4M trace_event=compaction:*"
	MEM=$(($MEM+32))
fi
PARAM="transparent_hugepage=never "$PARAM

setup_target "$KERNEL" "$MEM" "$PARAM"
launch_target
wait_target

setup_swap_zram $ZRAM_SIZE
setup_highalloc $HIGHALLOC_ORDER $HIGHALLOC_GFPFLAGS $HIGHALLOC_PERCENTAGE

setup_kernel_mem_pressure $FRAGALLOC_FREE_PERCENTAGE $FRAGALLOC_GFPFLAGS
setup_anonymous_mem_pressure $HOGGER_PRESSURE $SPREAD_HOGGER_PRESSURE
get_report

setup_build_pressure $BACKGROUND_BUILD_THREADS

get_report
run_highalloc
get_report

shutdown_target
