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
    -m 2G  -initrd ../initrd.img -hda ../qemu-rootfs/qemu-image.img \
    -append "root=/dev/sda rw crashkernel=256M console=ttyS0"   \
    -serial mon:stdio  \
    -serial telnet:localhost:4321,server,nowait \
    -display none 
```

## kdump and crash

1. load crash kernel 

```bash
kexec -p  /boot/bzImage --initrd=/boot/initrd.img --append="console=ttyS1 twin_kernel nr_cpus=1" 
```

2. trigger twin kernel to start

```bash
echo 0 > /sys/devices/system/cpu/cpu1/online
```

# 设计中的问题

- **problem 1** ：we need 2 serials
    - add a parameter `-serial telnet:localhost:4321,server,nowait`， conntecting with telnet `telnet localhost 4321` 。
- **problem 2** : if we use `telnet`, "Connection closed by foreigh host" when tiwnkernel booting.
    - 