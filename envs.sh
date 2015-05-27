#!/bin/bash

KERNEL=( bzImage-compaction-next-20150515-base bzImage-compaction-next-20150515-all )

GUEST_ID=js1304
HOME=/home/$GUEST_ID

# Should have linux kernel source
DIR_KERNEL_BUILD_BASE=$HOME/test-work/build-test/linux-3.0

# Should have mmtests benchmark
DIR_MMTESTS_BASE=$HOME/github/mmtests

DIR_BIN=$HOME/bin
BIN_MEM_HOGGER=$DIR_BIN/memory-hogger
BIN_PAGE_TYPES=$DIR_BIN/page-types
