#include <linux/twin_kernel.h>
#include <linux/kexec.h>

int is_twin_kernel_boot = 0;


void tk_start_kernel(void)
{
    pr_crit("[DB] tk_start_kernel");
    kexec_start_kernel();

    // no return
}

void tk_hold_starting(void)
{
    if (is_twin_kernel_boot) 
        while(1);
}