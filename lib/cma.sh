#!/bin/bash

setup_cma()
{
	local CMA_AREA=$1

	CMA_DEBUGFS_DIR=/sys/kernel/debug/cma/$CMA_AREA
}

get_success_cmaalloc()
{
	local NR_SUCCESS=`run_target_cmd "dmesg | grep cma" | grep returned | grep -v null | wc -l | awk '{ print $1 }'`

	echo "$NR_SUCCESS"
}

get_failed_cmaalloc()
{
	local NR_FAILED=`cat $RESULT_LOG | grep cma | grep returned | grep null | wc -l | awk '{ print $1 }'`

	echo "$NR_FAILED"
}

alloc_cma()
{
	local NR_PAGES=$1

	run_target_cmd "'sudo bash -c \"echo $NR_PAGES > $CMA_DEBUGFS_DIR/alloc\"'"
}

free_cma()
{
	local NR_PAGES=$1

	run_target_cmd "'sudo bash -c \"echo $NR_PAGES > $CMA_DEBUGFS_DIR/free\"'"
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
