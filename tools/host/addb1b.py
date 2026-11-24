import os
p = os.path.expanduser("~/Debian/m7642/tools/host/ckpt.py")
s = open(p).read()
if '"b1b"' not in s:
    s = s.replace('    "b1":           ("setup_arch", 0x368, "smp_init_cpus"),',
'''    "b1":           ("setup_arch", 0x368, "at bl smp_init_cpus"),
    "b1b":          ("setup_arch", 0x36c, "after smp_init_cpus returns"),
    "trap_init":    ("trap_init", 0x0, "trap_init entry"),
    "zonelists":    ("build_all_zonelists", 0x0, "build_all_zonelists entry"),
    "sort_extable": ("sort_main_extable", 0x0, "sort_main_extable entry"),''')
    open(p, "w").write(s); print("ckpt.py: b1b/trap_init/zonelists/sort_extable 已加")
