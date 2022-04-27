#include <linux/twin_kernel.h>
#include <linux/kexec.h>
#include <linux/init.h>

int twin_kernel_boot __initdata;
EXPORT_SYMBOL(twin_kernel_boot);

static int __init twin_kernel(char *str)
{
	pr_crit("[DB]: command line tk!\n");
    twin_kernel_boot = 1;
    return 0;
}
early_param("twin_kernel", twin_kernel);

void tk_start_kernel(void)
{
    pr_crit("[DB] tk_start_kernel");
    kexec_start_kernel();

    // no return
}
 
void tk_hold_starting(void)
{
    if (twin_kernel_boot) 
        while(1);
}