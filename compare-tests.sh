#!/bin/bash

source envs.sh
source lib/report.sh
source lib/cma.sh

MEM=512
REPEAT=1
ANALYSIS=0

compare_basic()
{
	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		compare_report
	done |
	awk -v seq=$REPEAT '{ arr[$1] += strtonum($2); } END {for (idx in arr) {printf("%-30s %d\n", idx, arr[idx]/strtonum(seq))}}' | sort
}

compare_cma()
{
	if [ "$BENCH_NAME" != "cma.sh" ]; then
		return;
	fi

	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		get_failed_cmaalloc $RESULT_LOG
	done | wc -l | awk '{ printf("%-30s %d\n", "CMA_fail", $1); }'

	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		get_cma_latency $RESULT_LOG
	done
}

ARGS=`getopt -o d:b:r: -- "$@"`
while true; do
	case "$1" in
		-r) REPEAT=$2; shift 2;;
		-d) DIR=$2; shift 2;;
		-b) BENCH_NAME=$2; shift 2;;
		*) break;;
	esac
done

if [ "$DIR" == "" ]; then
	echo "Usage: $0 -d [DIRECTORY] -r [REPEAT]"
	exit;
fi

if [ "$BENCH_NAME" == "cma.sh" ]; then
	MEM=1024
fi

for kernel in ${KERNEL[@]}; do
	echo "$kernel"

	compare_basic
	compare_cma

	echo ""
done;
