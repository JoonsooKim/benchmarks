#!/bin/bash

get_option()
{
	local i
	local OPTIONS=$1
	local KEYWORD=$2

	for OPTION in $OPTIONS; do
		echo $OPTION | grep $KEYWORD
	done

	return
}

get_value()
{
	local OPTIONS=$1
	local KEYWORD=$2
	local OPTION

	OPTION=`get_option "$OPTIONS" "$KEYWORD"`
	echo $OPTION | awk '
		{
			match ($0, /-[[:alnum:]]+$/)
			if (RSTART) {
				value = substr($0, RSTART+1, RLENGTH-1);
				print value
			}
		}'
}
