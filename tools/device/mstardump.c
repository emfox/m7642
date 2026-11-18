/*
 * mstardump - dump a physical memory range through /dev/miomap.
 *
 * mioreg only maps one 4 KiB window; this walks the range in chunks so a
 * whole firmware blob (ATF is ~0x40000) can be pulled in one go.
 *
 * MIOMAP_SET takes {phy, size} and the following mmap(0) exposes that window,
 * so the chunk size is passed straight to the driver. If the driver rejects a
 * large window, lower -c and retry.
 *
 * usage:
 *     mstardump <addr> <size> <outfile> [-c chunk]
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

struct miomap_param {
	uint64_t phy;
	uint64_t size;
};

#define MIOMAP_SET 0x40104901UL

static unsigned long chunk = 0x10000UL;

int main(int argc, char **argv)
{
	unsigned long addr, size;
	const char *out;
	struct miomap_param p;
	FILE *fp;
	int fd, i;
	unsigned long done = 0;

	if (argc < 4) {
		fprintf(stderr,
			"usage: %s <addr> <size> <outfile> [-c chunk]\n", argv[0]);
		return 2;
	}

	for (i = 4; i < argc; i++) {
		if (!strcmp(argv[i], "-c") && i + 1 < argc)
			chunk = strtoul(argv[++i], NULL, 0);
	}

	addr = strtoul(argv[1], NULL, 0);
	size = strtoul(argv[2], NULL, 0);
	out = argv[3];

	if (chunk & 0xfffUL) {
		fprintf(stderr, "chunk must be 4 KiB aligned\n");
		return 2;
	}

	fd = open("/dev/miomap", O_RDWR);
	if (fd < 0) {
		fprintf(stderr, "open /dev/miomap: %s\n", strerror(errno));
		return 1;
	}

	fp = fopen(out, "wb");
	if (!fp) {
		fprintf(stderr, "fopen %s: %s\n", out, strerror(errno));
		return 1;
	}

	while (done < size) {
		unsigned long cur = chunk;
		unsigned long phy = addr + done;
		void *map;

		if (cur > size - done)
			cur = size - done;

		p.phy = phy;
		p.size = cur;

		if (ioctl(fd, MIOMAP_SET, &p) < 0) {
			fprintf(stderr, "ioctl MIOMAP_SET %#lx/%#lx: %s\n",
				phy, cur, strerror(errno));
			fclose(fp);
			return 1;
		}

		map = mmap(NULL, cur, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
		if (map == MAP_FAILED) {
			fprintf(stderr, "mmap %#lx/%#lx: %s\n",
				phy, cur, strerror(errno));
			fclose(fp);
			return 1;
		}

		if (fwrite(map, 1, cur, fp) != cur) {
			fprintf(stderr, "fwrite at %#lx: %s\n", phy,
				strerror(errno));
			fclose(fp);
			return 1;
		}

		munmap(map, cur);
		done += cur;
	}

	fclose(fp);
	printf("dumped %#lx bytes from %#lx -> %s\n", done, addr, out);
	return 0;
}
