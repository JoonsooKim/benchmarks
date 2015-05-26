#!/bin/bash

source lib/report.sh

KERNEL=( bzImage-compaction-next-20150515-all )
MEM=512
REPEAT=1
ANALYSIS=0

ARGS=`getopt -o d:r: -- "$@"`
while true; do
	case "$1" in
		-r) REPEAT=$2; shift 2;;
		-d) DIR=$2; shift 2;;
		*) break;;
	esac
done

if [ "$DIR" == "" ]; then
	echo "Usage: $0 -d [DIRECTORY] -r [REPEAT]"
	exit;
fi

for kernel in ${KERNEL[@]}; do
	echo "$kernel"

	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		compare_report
	done |
	awk -v seq=$REPEAT '{ arr[$1] += strtonum($2); } END {for (idx in arr) {printf("%-30s %d\n", idx, arr[idx]/strtonum(seq))}}' | sort

	echo ""
done;
