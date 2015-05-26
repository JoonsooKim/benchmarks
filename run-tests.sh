SCRIPT_NAME=`basename $0`

KERNEL=( bzImage-compaction-next-20150515-all )
REPEAT=1
ANALYSIS=0

usage()
{
	echo "Invalid usage: $SCRIPT_NAME -b [BENCH_NAME] -t [BENCH_TYPE] -r [REPEAT] -a [1:trace 2:page-owner 3:all]";
	exit;
}

check_argument()
{
	if [ "$BENCH_NAME" == "" ]; then
		usage;
	fi

	echo "$BENCH_NAME"
	echo "$BENCH_TYPE"
	echo "$REPEAT"
	echo "$ANALYSIS"
}

################
##### Main #####
################

ARGS=`getopt -o b:t:r:a: -- "$@"`
while true; do
	case "$1" in
		-b) BENCH_NAME=$2; shift 2;;
		-t) BENCH_TYPE=$2; shift 2;;
		-r) REPEAT=$2; shift 2;;
		-a) ANALYSIS=$2; shift 2;;
		*) break;;
	esac
done

check_argument;

for trial in `seq 1 $REPEAT`; do
	for kernel in ${KERNEL[@]}; do
		bash tests/$BENCH_NAME $trial $kernel $ANALYSIS $BENCH_TYPE
	done;
done;
