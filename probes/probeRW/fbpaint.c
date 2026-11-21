// fbpaint: report the framebuffer's physical address and flood it.
//
//   fbpaint /dev/graphics/fb0 0x0000ff00 info   # just print fix/var
//   fbpaint /dev/graphics/fb0 0x0000ff00        # flood with a colour
//
// Going through /dev/fb0 rather than poking the physical address matters: the
// mapping is set up by the driver, so cache maintenance and the WC attribute
// are already right.  Writing the same bytes through the linear map leaves
// them in the CPU cache and the scanout engine never sees them.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/fb.h>

int main(int argc, char **argv)
{
	const char *dev = "/dev/graphics/fb0";
	unsigned int color = 0x0000ff00;
	struct fb_fix_screeninfo fix;
	struct fb_var_screeninfo var;
	void *p;
	int fd;

	if (argc > 1)
		dev = argv[1];
	if (argc > 2)
		color = (unsigned int)strtoul(argv[2], NULL, 0);

	fd = open(dev, O_RDWR);
	if (fd < 0) {
		fprintf(stderr, "open %s: %m\n", dev);
		return 1;
	}
	if (ioctl(fd, FBIOGET_FSCREENINFO, &fix)) {
		fprintf(stderr, "FBIOGET_FSCREENINFO: %m\n");
		return 1;
	}
	if (ioctl(fd, FBIOGET_VSCREENINFO, &var)) {
		fprintf(stderr, "FBIOGET_VSCREENINFO: %m\n");
		return 1;
	}

	printf("id=%s smem_start=%#lx smem_len=%u line_length=%u accel=%u\n",
	       fix.id, (unsigned long)fix.smem_start, fix.smem_len,
	       fix.line_length, fix.accel);
	printf("vis=%ux%u virt=%ux%u bpp=%u\n",
	       var.xres, var.yres, var.xres_virtual, var.yres_virtual,
	       var.bits_per_pixel);

	if (argc > 3 && !strcmp(argv[3], "info"))
		return 0;

	if (!fix.smem_len) {
		fprintf(stderr, "smem_len is 0, nothing to map\n");
		return 1;
	}

	p = mmap(NULL, fix.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (p == MAP_FAILED) {
		fprintf(stderr, "mmap: %m\n");
		return 1;
	}

	/* "peek" reads back what is actually in DRAM right now, so a caller can
	 * tell "my write reached the scanout buffer" apart from "it only made it
	 * into the CPU cache". */
	if (argc > 3 && !strcmp(argv[3], "peek")) {
		unsigned int *q = p;
		int i;

		for (i = 0; i < 16; i++)
			printf("%08x%c", q[i], (i % 8 == 7) ? '\n' : ' ');
		munmap(p, fix.smem_len);
		return 0;
	}

	{
		unsigned int *q = p;
		size_t n = fix.smem_len / 4;
		size_t i;

		for (i = 0; i < n; i++)
			q[i] = color;
	}

	munmap(p, fix.smem_len);
	printf("flooded %u bytes with %#x\n", fix.smem_len, color);
	return 0;
}
