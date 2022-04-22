# Twin Kernel

基于 Linux 5.15.33 版本

# QEMU

qemu 启动参数

```
sudo qemu-system-x86_64 -kernel arch/x86/boot/bzImage   -m 2G  -initrd ../initrd.img -hda ../qemu-rootfs/qemu-image.img  -append "root=/dev/sda  console=ttyS0" -serial stdio -display none
```

# rootfs 基本依赖

- kexc-tool