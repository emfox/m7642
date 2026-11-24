import os
p = os.path.expanduser("~/Debian/m7642/tools/host/ckpt.py")
s = open(p).read()
if '"pre_mmcore"' not in s:
    s = s.replace('    "sort_extable": ("sort_main_extable", 0x0, "sort_main_extable entry"),',
'''    "sort_extable": ("sort_main_extable", 0x0, "sort_main_extable entry"),
    # start_kernel's tail: setup_log_buf -> vfs_caches_init_early ->
    # sort_main_extable -> mm_core_init -> sched_init, all inlined in start_kernel
    "pre_logbuf":   ("start_kernel", 0x3a4, "at bl setup_log_buf"),
    "pre_vfsearly": ("start_kernel", 0x3a8, "at bl vfs_caches_init_early"),
    "pre_sortext":  ("start_kernel", 0x3ac, "at bl sort_main_extable"),
    "pre_mmcore":   ("start_kernel", 0x3b4, "at bl mm_core_init"),
    "post_mmcore":  ("start_kernel", 0x3b8, "after mm_core_init returns"),
    "pre_sched":    ("start_kernel", 0x3c0, "at bl sched_init"),''')
    open(p, "w").write(s); print("ckpt.py: start_kernel 尾部阶梯已加")
