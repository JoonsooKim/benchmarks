#!/bin/bash

setup_target()
{
	TARGET_LAUNCH="cd ~/qemu-img; bash boot.sh \"$1\" \"$2\" \"$3\""
	TARGET_CONNECT="ssh localhost -p 7777"
	TARGET_SCP="scp -r -P 7777 localhost"
}

launch_target()
{
	local i

	for i in `seq 1 10`; do
		QEMU_EXIST=`ps aux | grep qemu-system | grep ubuntu | wc -l`
		if [ "$QEMU_EXIST" == "1" ]; then
			sleep 10
		fi
	done;

	# Clean-up previous QEMU
	local QEMU_EXIST=`ps aux | grep qemu-system | grep ubuntu | wc -l`
	if [ "$QEMU_EXIST" == "1" ]; then
		PID=`ps aux | grep qemu-system | grep ubuntu | awk '{print $2}'`
		kill -9 $PID
	fi

	echo "$TARGET_LAUNCH"
	bash -c "$TARGET_LAUNCH" &> /dev/null &
}

wait_target()
{
	local i

	sleep 10
	for i in `seq 1 10`; do
		sleep 10
		local QEMU_EXIST=`ps aux | grep qemu-system | grep ubuntu | wc -l`
		if [ "$QEMU_EXIST" != "1" ]; then
			continue;
		fi

		run_target_cmd "ls" &> /dev/null
		if [ "$?" == "0" ]; then
			echo "Target launched"
			return;
		fi
	done

	echo "Target not launched"
	exit;
}

run_target_cmd()
{
	local CMD=$1
	local QUIET=$2
	local TIME=`date | sed 's/\n//g'`

	echo "$TIME: Do \"$CMD\""

	if [ "$QUIET" == "1" ]; then
		bash -c "$TARGET_CONNECT $CMD" &> /dev/null
	else
		bash -c "$TARGET_CONNECT $CMD"
	fi
}

run_target_scp()
{
	local SRC_PATH=$1
	local DST_PATH=$2

	bash -c "$TARGET_SCP:$SRC_PATH $DST_PATH"
}

shutdown_target()
{
	run_target_cmd "sudo shutdown -h now"
}
