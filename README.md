# Twin Kernel

基于双内核的内核热升级方法。[oscomp: proj135-seamless-kernel-upgrade](https://github.com/oscomp/proj135-seamless-kernel-upgrade)

```
          | ------------------------------------ |
          |     Kernel  A   |      Kernel B      |
          |--------------------------------------|
          |               hardware               |
          |--------------------------------------|
```
 

# Design

- kexec
- cpu hotplug 
- pci black list


# Implementation

## qemu 

### qemu boot options

```bash
sudo qemu-system-x86_64 -kernel bzImage \
    -smp 2 \
    --enable-kvm \
    -m 2G  \
    -hda ./qemu-rootfs/qemu-img-5G.img \
    -append "root=/dev/sda rw crashkernel=256M console=ttyS0"   \
    -serial telnet:localhost:4321,server,nowait \
    -vga std
```


使用 virsh 启动，virsh 下虚拟机的[配置文件示例可见](_files/tk_kernel_boot.xml)

## kdump and crash

1. load crash kernel 

```bash

# kexec -p  /boot/bzImage --initrd=/boot/initrd.img  \
kexec -p  /boot/bzImage --initrd=/boot/rootfs.img  \
--append="console=ttyS0 twin_kernel nr_cpus=1 \ 
 acpi_irq_nobalance no_ipi_broadcast=1 lapic_timer=1000000 \
 rdinit=/linuxrc \
 pci_dev_flags=0x8086:0x100e:b,0x8086:0x1237:b,0x8086:0x7000:b,0x8086:0x7010:b,0x8086:0x7113:b,0x1234:0x1111:b"
```

2. trigger twin kernel to start

```bash
echo 0 > /sys/devices/system/cpu/cpu1/online
```

# 设计中的问题和解决方案

- **Problem 1** ：需要 2 个 串口
    - add a parameter `-serial telnet:localhost:4321,server,nowait`， conntecting with telnet `telnet localhost 4321` 。
- **Problem 2** : pci device 冲突
    - 在 pci_scan_single_device() 函数中增加 blacklist 判断
- **Problem 3** : 串口重初始化
- 从自编译和制作的 rootfs 启动无法分配 IP 地址
    -  尝试了 [cirros 镜像方式启动](https://www.voidking.com/dev-libvirt-create-vm/)可动态分配IP，考虑是自制作rootfs的问题，因此抛弃原方式尝试做一个 ubuntu20.04 server 镜像

# 环境配置

## Linux kernel

Linux kernel 5.15.33

```
make defconfig
make kvm_guest.config
make -j`nproc`
```

## qemu

```bash

$ wget https://download.qemu.org/qemu-4.2.1.tar.xz
$ tar -xvf qemu-4.2.1.tar.xz
$ cd qemu-4.2.1
$ ./configure --enable-kvm  --target-list=x86_64-softmmu
make

$ sudo make install 

$ qemu-system-x86_64 --version
QEMU emulator version 4.2.1
Copyright (c) 2003-2019 Fabrice Bellard and the QEMU Project developers

```

## Ubuntu 镜像制作

1. 基本镜像

基本镜像给 first kernel 使用

```bash

SCRIPTS_PATH="./tk/scripts/"
IMAGE_PATH="./tk/images"

sudo apt install debootstrap

chmod u+x $SCRIPTS_PATH/*.sh

$SCRIPTS_PATH/mk-qemu-img.sh $IMAGE_PATH/qemu-img-5G.img 5G

$SCRIPTS_PATH/mount-img.sh $IMAGE_PATH/qemu-img-5G.img
# lspci
sudo cp /usr/bin/lspci mount-point.tmp/usr/bin/
sudo cp /usr/lib/x86_64-linux-gnu/libpci.so.3 mount-point.tmp/usr/lib/x86_64-linux-gnu/

LC_ALL=C LANGUAGE=C LANG=C sudo chroot mount-point.tmp
# gawk
apt install vim gawk kexec-tools -y
apt remove systemd
apt install init

# 修改密码
passwd

# ctrl+d 退出

$SCRIPTS_PATH/umount-img.sh

# or 直接全拷贝(不推荐)
sudo cp /usr/bin/* mount-point.tmp/usr/bin/
sudo cp /usr/lib/x86_64-linux-gnu/* mount-point.tmp/usr/lib/x86_64-linux-gnu/
```

2. 使用 busybox 制作简单 rootfs 给 second kernel 使用

参考 [BusyBox_Rootfs.md](tk/docs/BusyBox_Rootfs.md)

```bash
# 待完善
```

3. 将 Twinkernel 和 rootfs 放置到镜像中

```bash

IMAGE_PATH="./tk/images"
$SCRIPTS_PATH/install_kernel_to_img.sh $IMAGE_PATH/qemu-img-5G.img

```
