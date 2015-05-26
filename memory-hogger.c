#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#define MAX_WAIT_US (10000)
#define PAGE_SIZE (4096)
#define SIZE_MB (1024 * 1024)
//#define TEST_FILE "/home/js1304/qemu-img/ubuntu-server.img"
#define TEST_FILE "/home/js1304/vmlinux"
#define LEN_PROC_PATH (256)

static void usage(char *argv[])
{
	printf("%s memory size(MB unit[1 ~ 4096])\n", argv[0]);
}

static int page_zero_filled(unsigned long *buf)
{
	int start;
	int end = PAGE_SIZE / sizeof(unsigned long);

	for (start = 0; start < end; start++) {
		if (buf[start])
			return 0;
	}

	return 1;
}

static void dirty_page(char *buf)
{
	char c;

	c = *buf;
	*buf = c;
}

static void rand_wait()
{
	int num;

	num = rand();
	num = num % MAX_WAIT_US;
	if (num < MAX_WAIT_US * 7 / 8)
		return;

	usleep(num);
}

static char proc_buff[LEN_PROC_PATH];

int main(int argc, char *argv[])
{
	unsigned long size_mb;
	size_t size_b, map_size_b;
	char *buf;
	int fd;
	size_t i, dirty;
	time_t begin, end;
	pid_t pid, sid;

	if (argc != 2) {
		usage(argv);
		return 0;
	}

	size_mb = atol(argv[1]);
	if (size_mb < 1 || size_mb > 4096) {
		usage(argv);
		return 0;
	}

	sid = setsid();
	if (sid < 0) {
		printf("Setsid failed\n");
		return 0;
	}

	pid = getpid();
	memset(proc_buff, 0, LEN_PROC_PATH);
	sprintf(proc_buff, "/proc/%d/oom_score_adj", pid);
	fd = open(proc_buff, O_RDWR);
	if (fd < 0) {
		printf("Open failed\n");
		return 0;
	}

	write(fd, "-1000", 5);
	close(fd);

	size_b = 1024 * 1024 * size_mb;

	/* Map 1 time larger region to skip zero page */
	map_size_b = size_b * 1;
	fd = open(TEST_FILE, O_RDWR);
	if (fd < 0) {
		printf("Open failed\n");
		return 0;
	}

	buf = mmap(NULL, map_size_b, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
	if (!buf) {
		printf("Out of memory: %lu\n", size_b);
		return 0;
	}
	close(fd);

	begin = time(NULL);
	for (i = 0, dirty = 0; i < map_size_b; i += PAGE_SIZE) {
		if (dirty != 0 && dirty % SIZE_MB == 0) {
			end = time(NULL);
			printf("Dirtying %lu mb in %lu mb region during %lu secs\n",
				dirty / SIZE_MB, i / SIZE_MB, end - begin);
		}

		if (page_zero_filled((unsigned long *)(&buf[i])))
			continue;

		dirty_page(&buf[i]);
		dirty += PAGE_SIZE;
		if (dirty > size_b)
			break;

		rand_wait();
	}

	end = time(NULL);
	printf("Dirtying %lu mb in %lu mb region during %lu secs\n",
		dirty / SIZE_MB, i / SIZE_MB, end - begin);

	printf("Go into infinite sleep\n");
	sleep(100000);

	return 0;
}
