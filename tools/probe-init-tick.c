/* per-second tick probe /init (ver=15)
 * Writes {magic, ver, second, ms} to the report page once per second for up to
 * 90 s, then panics so the checkpoint probe hands back to the factory kernel.
 * The last second written tells us exactly when the kernel stopped making
 * progress (if it dies before finishing).
 */
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/mount.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>

#define REPORT_PA 0x23081000UL
#define LOG_PA    0x23082000UL
#define LOG_MAX   0x10000
#define MAXSEC    90

struct report {
	uint32_t magic, ver;
	int64_t  md, mp, ms;
	int64_t  t_start_ms;
	int64_t  second;       /* last completed second */
	int64_t  t_last_ms;
	int64_t  mmc_open, mmc_errno;
	int64_t  syslog_ret, sysrq_ret;
	uint32_t done;
};

static int64_t now_ms(void)
{
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

int main(void)
{
	static struct report r;
	static char buf[LOG_MAX];
	memset(&r, 0, sizeof(r));
	r.magic = 0x4d373634; r.ver = 15;

	r.md = mount("devtmpfs", "/dev", "devtmpfs", 0, NULL) ? -errno : 0;
	r.mp = mount("proc", "/proc", "proc", 0, NULL) ? -errno : 0;
	r.ms = mount("sysfs", "/sys", "sysfs", 0, NULL) ? -errno : 0;
	r.t_start_ms = now_ms();

	int m = open("/dev/mem", O_RDWR | O_SYNC);
	if (m >= 0) {
		void *rp = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, m, REPORT_PA);
		if (rp != MAP_FAILED) {
			for (int s = 0; s <= MAXSEC; s++) {
				r.second  = s;
				r.t_last_ms = now_ms();
				memcpy(rp, &r, sizeof(r));
				msync(rp, 4096, MS_SYNC);
				if (s < MAXSEC)
					sleep(1);
			}
		}
		close(m);
	}

	{ int fd = open("/dev/mmcblk0", O_RDONLY); r.mmc_open = fd; r.mmc_errno = fd < 0 ? -errno : 0; if (fd >= 0) close(fd); }
	long n = syscall(SYS_syslog, 3, buf, (long)sizeof(buf));
	r.syslog_ret = n;
	m = open("/dev/mem", O_RDWR | O_SYNC);
	if (m >= 0) {
		void *rp = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, m, REPORT_PA);
		if (n > 0) {
			void *lp = mmap(NULL, LOG_MAX, PROT_READ|PROT_WRITE, MAP_SHARED, m, LOG_PA);
			if (lp != MAP_FAILED) { memcpy(lp, buf, (size_t)n); msync(lp, LOG_MAX, MS_SYNC); }
		}
		if (rp != MAP_FAILED) { memcpy(rp, &r, sizeof(r)); msync(rp, 4096, MS_SYNC); }
	}
	int k = open("/proc/sysrq-trigger", O_WRONLY);
	r.sysrq_ret = k;
	if (k >= 0) { if (write(k, "c", 1) < 0) {} close(k); }
	for (;;) pause();
}
