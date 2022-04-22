# Twin Kernel

基于 Linux 5.15.33 版本

# Implementation

## qemu 

### qemu 启动参数相关

```bash
sudo qemu-system-x86_64 -kernel arch/x86/boot/bzImage   -m 2G  -initrd ../initrd.img -hda ../qemu-rootfs/qemu-image.img  -append "root=/dev/sda crashkernel=128M console=ttyS0" -serial stdio -display none -serial telnet:localhost:4321,server,nowait
```

**问题 1** ：开启两个 serial

**解决方案** ：增加 qemu 参数 `-serial telnet:localhost:4321,server,nowait`， 通过 telnet 连接 `telnet localhost 4321` 。


## kexec load

```bash
kexec -p  /boot/bzImage --initrd=/boot/initrd.img --append=
```

# rootfs 基本依赖

- kexc-tool