#!/bin/bash
source envs.sh
source lib/target-system.sh
source lib/report.sh

SEQ=$1
KERNEL=$2
ANALYSIS=$3
BENCH_TYPE=$4
MEM=4096

run_mmtests()
{
	local TEST_SEQ=$1

	run_target_cmd "rm -rf $DIR_MMTESTS_BASE/work/testdisk/tmp"
	run_target_cmd "\"(cd $DIR_MMTESTS_BASE; ./run-mmtests.sh $KERNEL $TEST_SEQ)\""
	run_target_cmd "rm -rf $DIR_MMTESTS_BASE/work/testdisk/tmp"
}

get_mmtests_output()
{
	local TEST_SEQ=$1
	local DIR_MMTESTS_OUTPUT=$DIR/$TEST_SEQ

	mkdir -p $DIR_MMTESTS_OUTPUT
	run_target_scp "$DIR_MMTESTS_BASE/work/log/$TEST_SEQ/*$KERNEL*" "$DIR_MMTESTS_OUTPUT"
}

run_mmtests_basic()
{
	get_report
	run_mmtests $SEQ
	get_report
	get_mmtests_output $SEQ
}

run_mmtests_repeat()
{
	local i
	local TEST_SEQ

	for i in `seq 1 3`; do
		TEST_SEQ="$SEQ-$i"

		get_report
		run_mmtests $TEST_SEQ
		get_report
		get_mmtests_output $TEST_SEQ
	done

}

#### Start benchmark ####
if [ "$BENCH_TYPE" != "basic" ] && [ "$BENCH_TYPE" != "repeat" ]; then
	exit;
fi

DIR=result-stress-highalloc-$BENCH_TYPE

setup_report "$KERNEL" "$MEM" "$SEQ" "$DIR" "$ANALYSIS"
clear_result_log
if [ "$TRACEPOINT_ON" == "1" ]; then
	PARAM="trace_buf_size=4M trace_event=compaction:*"
fi
if [ "$PAGEOWNER_ON" == "1" ]; then
	PARAM="page_owner=on "$PARAM
fi
PARAM="transparent_hugepage=never log_buf_len=32M "$PARAM

setup_target "$KERNEL" "$MEM" "$PARAM"
launch_target
wait_target

get_report

if [ "$BENCH_TYPE" == "basic" ]; then
	run_mmtests_basic
elif [ "$BENCH_TYPE" == "repeat" ]; then
	run_mmtests_repeat
fi

shutdown_target
