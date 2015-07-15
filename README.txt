* How to run the benchmark?

0. Prerequisite
Utils: build-essential, swapoff, mkswap, swapon, sleep in target machine
Kernel: Should be compiled with ZRAM, COMPACTION
	Should be patched with patches in patches/*

1. Build memory hogger (static)
- Build memory-hogger.c to make memory pressure. Copy binary
 to appropriate directory in target machine. See envs.sh.

2. Copy kernel source code
- Put linux kernel source code to DIR_KERNEL_BUILD_BASE in target
 machine in order to make memory pressure through kernel build.

3. Adjust envs.sh

4. Adjust lib/target-system.sh
- This benchmark is implemented for QEMU target system.
 If you'd like to use real target machine, you should
 modify some functions in lib/target-system.sh to communicate
 with target machine properly.

5. Run and Enjoy!
