/*
 * cpathmin.c -- minimal compiled code for the code1 C-path test.
 * cpath_entry() must return 0x42; the stub records it.
 */
typedef unsigned long u64;

static u64 cpath_helper(u64 x)
{
	return x + 1;
}

u64 cpath_entry(void)
{
	return cpath_helper(0x41);
}
