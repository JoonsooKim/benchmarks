#!/bin/bash

get_compaction_normalized_success()
{
	if [ "$BENCH_NAME" != "compaction.sh" ]; then
		return;
	fi

	TOTAL_POSSIBILITY=0
	TOTAL_SUCCESS_ALLOCS=0
	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		POSSIBILITY=`frag-analyzer.sh -t page_types -f $RESULT_PAGE_TYPES".1" -s | grep Compaction | awk '{print $5}'`
		SUCCESS_ALLOCS=`cat $RESULT_LOG | grep "Success allocs:" | awk '{print $3}'`
		if [ $POSSIBILITY == "0" ]; then
			POSSIBILITY=0;
			SUCCESS_ALLOCS=0;
		fi

		TOTAL_POSSIBILITY=$(($TOTAL_POSSIBILITY+$POSSIBILITY))
		TOTAL_SUCCESS_ALLOCS=$(($TOTAL_SUCCESS_ALLOCS+$SUCCESS_ALLOCS))
	done

	PERCENTAGE=$(($TOTAL_SUCCESS_ALLOCS*100/$TOTAL_POSSIBILITY))
	echo $PERCENTAGE | awk '{printf("%-30s\t%20d\n", "Success(N):", $1)}'
}

extract_compaction_graphdata()
{
	GRAPH_DATA_FILE=$DIR/graphdata-$kernel-$MEM".txt"

	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		cat $RESULT_LOG | grep "vm events" | \
		awk '
			{ if(strtonum($6)==0) base = strtonum($14); success[$6] += strtonum($7); pgmigrate[$6] += (strtonum($14) - base); }
			END {
				for (idx in success)
					printf("%-30s %d %d\n", idx, success[idx], pgmigrate[idx])
			}
		' | sort -n >  $RESULT_GRAPHDATA
	done
}


make_compaction_tmp_graphdata()
{
	TMP_GRAPHDATA=$DIR/tmp-graphdata-$kernel-$MEM".txt"

	for trial in `seq 1 $REPEAT`; do
		setup_report $kernel $MEM $trial $DIR $ANALYSIS
		cat $RESULT_GRAPHDATA
	done | awk -v seq=$REPEAT '
		BEGIN { seq = strtonum(seq) }
		{ success[$1] += strtonum($2); pgmigrate[$1] += strtonum($3); }
		END {
			for (idx in success)
				printf("%-30s %d %d\n", idx, success[idx]/seq, pgmigrate[idx]/seq)
		}
	' | sort -n > $TMP_GRAPHDATA
}

draw_compaction_graph()
{
	if [ "$BENCH_NAME" != "compaction.sh" ]; then
		return;
	fi

	TMP_GRAPHDATA=$DIR/tmp-graphdata-$kernel-$MEM".txt"
	TMP_GNUPLOT=$DIR/tmp-gnuplot-$MEM".gpi"
	RESULT_GRAPH=$DIR/graph-$MEM".png"

	for kernel in ${KERNEL[@]}; do
		extract_compaction_graphdata
	done;

	for kernel in ${KERNEL[@]}; do
		make_compaction_tmp_graphdata
	done;

	# Build gnuplot command
	echo "set terminal png" > $TMP_GNUPLOT
	echo "set output \"$RESULT_GRAPH\"" >> $TMP_GNUPLOT
	echo "set y2tics" >> $TMP_GNUPLOT

	echo "plot \\" >> $TMP_GNUPLOT
	for kernel in ${KERNEL[@]}; do
		TMP_GRAPHDATA=$DIR/tmp-graphdata-$kernel-$MEM".txt"

		echo "\"$TMP_GRAPHDATA\" using 1:2 with linespoint title \""$kernel"(success)\", \\" >> $TMP_GNUPLOT
	done;

	for kernel in ${KERNEL[@]}; do
		TMP_GRAPHDATA=$DIR/tmp-graphdata-$kernel-$MEM".txt"

		echo "\"$TMP_GRAPHDATA\" using 1:3 with linespoint title \""$kernel"(pgmigrate)\" axes x1y2, \\" >> $TMP_GNUPLOT
	done;

	echo "" >> $TMP_GNUPLOT

	gnuplot $TMP_GNUPLOT
}
