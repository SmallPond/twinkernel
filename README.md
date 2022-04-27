# Twin Kernel

基于双内核的内核热升级方法

Linux kernel 5.15.33 

# Design

kexec + cpu hotplug

# Implementation

## qemu 

### qemu boot options

```bash
sudo qemu-system-x86_64 -kernel arch/x86/boot/bzImage \
    -smp 2 \
    -m 2G  -initrd ../initrd.img -hda ../qemu-rootfs/qemu-img-5G.img \
    -append "root=/dev/sda rw crashkernel=256M console=ttyS0"   \
    -serial mon:stdio  \
    -serial telnet:localhost:4321,server,nowait \
    -display none 
```

## kdump and crash

1. load crash kernel 

```bash
kexec -p  /boot/bzImage --initrd=/boot/initrd.img  \
    --append="console=ttyS1 twin_kernel nr_cpus=1 earlyprintk=ttyS1,115200  acpi_irq_nobalance no_ipi_broadcast=1 lapic_timer=1000000 pci_dev_flags=0101:8086:7010:b,0200:8086:100e:b,0300:1234:1111:b,0601:8086:7000:b,0680:8086:7113:b,0x8086:0x7010:b,0x8086:0x100e:b,0x1234:0x1111:b,0x8086:0x7000:b,0x8086:0x7113:b"
```

2. trigger twin kernel to start

```bash
echo 0 > /sys/devices/system/cpu/cpu1/online
```

# 设计中的问题和解决方案

- **Problem 1** ：需要 2 个 串口
    - add a parameter `-serial telnet:localhost:4321,server,nowait`， conntecting with telnet `telnet localhost 4321` 。
- ***Problem 2** : pci device 冲突
    - 在 pci_scan_single_device() 函数中增加 blacklist 判断

# 依赖的命令

```
# lspci
sudo cp /usr/bin/lspci mount-point.tmp/usr/bin/
sudo cp /usr/lib/x86_64-linux-gnu/libpci.so.3 mount-point.tmp/usr/lib/x86_64-linux-gnu/
# gawk
apt install gawk

# or 直接全拷贝(不推荐)
sudo cp /usr/bin/* mount-point.tmp/usr/bin/
sudo cp /usr/lib/x86_64-linux-gnu/* mount-point.tmp/usr/lib/x86_64-linux-gnu/
```