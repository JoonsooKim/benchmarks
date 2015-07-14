#!/bin/bash

setup_cma()
{
	local CMA_AREA=$1

	CMA_DEBUGFS_DIR=/sys/kernel/debug/cma/$CMA_AREA
}

get_success_cmaalloc()
{
	run_target_cmd "sudo cat $CMA_DEBUGFS_DIR/used" | grep -v "Do" | awk '{ print $1 }'
}

alloc_cma()
{
	local NR_ALLOCS=$1
	local SEQS=`seq -s " " 1 $NR_ALLOCS`
	local NR_PAGES=$2

	run_target_cmd "'sudo bash -c \"for i in $SEQS; do echo $NR_PAGES > $CMA_DEBUGFS_DIR/alloc; sleep 1; done;\"'"
}

free_cma()
{
	local NR_ALLOCS=$1
	local SEQS=`seq -s " " 1 $NR_ALLOCS`
	local NR_PAGES=$2

	run_target_cmd "'sudo bash -c \"for i in $SEQS; do echo $NR_PAGES > $CMA_DEBUGFS_DIR/free; done;\"'"
}

get_cma_latency()
{
	local RESULT_LOG=$1

	cat $RESULT_LOG | grep cma | grep returned -B 1 | grep -v null -B 1 | awk '
		{
			line++;
			match($2, /[0-9]+\.[0-9]+/)
			if (RSTART) {
				time = substr($2, RSTART, RLENGTH)
				arr[line] = strtonum(time);
			}

			if (line % 2 == 1)
				next;

			sum += arr[line] - arr[line - 1];
			count++;
		}
		END {
			printf("%-30s %f\n", "Latency", sum / count);
		}'
}
