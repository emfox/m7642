/* M7642 userspace report channel.
 * Userspace cannot talk to us (no console/UART), so:
 *   1) do the work we want to verify,
 *   2) record every result into PA 0x23081000 (survives the handover, which
 *      only overwrites 0x20280000..0x21554A00),
 *   3) trigger a SysRq crash so the kernel panics; the panic checkpoint hands
 *      over to the factory kernel, Android comes up and we read the page back.
 */
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/mount.h>
#include <unistd.h>

#define REPORT_PA 0x23081000UL

struct report {
	uint32_t magic;          /* 0x4d373634 "M764" */
	uint32_t ver;
	int64_t  mount_dev, mount_proc, mount_sys;
	int64_t  mem_open, mem_errno;
	int64_t  fb_mmap, fb_errno;
	uint32_t fb_first, fb_mid, fb_last;
	int64_t  sysrq_open, sysrq_errno;
	uint32_t done;
};

static void put(struct report *r)
{
	int fd = open("/dev/mem", O_RDWR | O_SYNC);
	if (fd < 0) return;
	void *p = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, REPORT_PA);
	if (p != MAP_FAILED) { memcpy(p, r, sizeof(*r)); msync(p, 4096, MS_SYNC); }
	close(fd);
}

int main(void)
{
	static struct report r;
	memset(&r, 0, sizeof(r));
	r.magic = 0x4d373634; r.ver = 1;

	r.mount_dev  = mount("devtmpfs", "/dev", "devtmpfs", 0, NULL) ? -errno : 0;
	r.mount_proc = mount("proc", "/proc", "proc", 0, NULL) ? -errno : 0;
	r.mount_sys  = mount("sysfs", "/sys", "sysfs", 0, NULL) ? -errno : 0;

	int fd = open("/dev/mem", O_RDWR | O_SYNC);
	r.mem_open = fd; r.mem_errno = fd < 0 ? -errno : 0;
	if (fd >= 0) {
		const off_t FB = 0x2D100000;
		const size_t LEN = 0x800000;
		void *p = mmap(NULL, LEN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, FB);
		r.fb_mmap = (int64_t)p; r.fb_errno = (p == MAP_FAILED) ? -errno : 0;
		if (p != MAP_FAILED) {
			volatile uint32_t *px = (volatile uint32_t *)p;
			r.fb_first = px[0]; r.fb_mid = px[(LEN / 4) / 2]; r.fb_last = px[LEN / 4 - 1];
			for (size_t i = 0; i < LEN / 4; i++) px[i] = 0x0000FF00;
		}
		close(fd);
	}

	put(&r);   /* report before crashing */

	int k = open("/proc/sysrq-trigger", O_WRONLY);
	r.sysrq_open = k; r.sysrq_errno = k < 0 ? -errno : 0;
	put(&r);
	if (k >= 0) { if (write(k, "c", 1) < 0) {} close(k); }

	r.done = 0xdeadbeef;
	put(&r);
	for (;;) pause();
}
