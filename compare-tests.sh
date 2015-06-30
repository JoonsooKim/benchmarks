#!/bin/bash

source envs.sh
source lib/report.sh
source lib/cma.sh
source lib/compaction.sh

MEM=512
REPEAT=1
ANALYSIS=0
REPEAT_HIGHALLOC=1

compare_basic()
{
#	if [ "$REPEAT_HIGHALLOC" != "1" ]; then
#		return;
#	fi

	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		compare_report
	done |
	awk -v seq=$REPEAT '{ val = strtonum($2); arr[$1] += val; arr2[$1] += (val * val); } END {for (idx in arr) {x2 = arr2[idx]/strtonum(seq); avg = arr[idx]/strtonum(seq); std=sqrt(x2-(avg*avg)); printf("%-30s\t%20d\t%10.2f\n", idx, avg, std)}}' | sort
}

compare_pageblock()
{
	local SEQ;
	local IDX;

	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		for SEQ in `seq 1 $REPEAT_HIGHALLOC`; do
			IDX=$(($SEQ*2+1))
			compare_pagetypeinfo $IDX
		done;
	done |
	awk -v seq=$REPEAT '{ val = strtonum($2); arr[$1] += val; arr2[$1] += (val * val); } END {for (idx in arr) {x2 = arr2[idx]/strtonum(seq); avg = arr[idx]/strtonum(seq); std=sqrt(x2-(avg*avg)); printf("%-30s\t%20d\t%10.2f\n", idx, avg, std)}}' | sort
}

compare_cma()
{
	if [ "$BENCH_NAME" != "cma.sh" ]; then
		return;
	fi

	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		get_failed_cmaalloc $RESULT_LOG
	done | wc -l | awk '{ printf("%-30s\t%20d\n", "CMA_fail", $1); }'

	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		get_cma_latency $RESULT_LOG
	done
}

ARGS=`getopt -o d:b:r:k: -- "$@"`
while true; do
	case "$1" in
		-r) REPEAT=$2; shift 2;;
		-d) DIR=$2; shift 2;;
		-b) BENCH_NAME=$2; shift 2;;
		-k) KERNEL=( "$2" ); shift 2;;
		*) break;;
	esac
done

if [ "$DIR" == "" ]; then
	echo "Usage: $0 -d [DIRECTORY] -r [REPEAT] -b [BENCH)NAME] -k [KERNEL]"
	exit;
fi

if [ "$BENCH_NAME" == "compaction-pageblock.sh" ]; then
	REPEAT_HIGHALLOC=5
fi

if [ "$BENCH_NAME" == "stress-highalloc.sh" ]; then
	MEM=4096
fi

if [ "$BENCH_NAME" == "stress-highalloc-pageblock.sh" ]; then
	MEM=4096
	REPEAT_HIGHALLOC=3
fi

if [ "$BENCH_NAME" == "cma.sh" ]; then
	MEM=1024
fi

for kernel in ${KERNEL[@]}; do
	echo "$kernel"

	compare_basic
	compare_pageblock
	compare_cma
	get_compaction_normalized_success

	echo ""
done;

draw_compaction_graph;
