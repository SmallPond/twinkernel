# Twin Kernel

基于双内核的内核热升级方法。[oscomp: proj135-seamless-kernel-upgrade](https://github.com/oscomp/proj135-seamless-kernel-upgrade)

现在数据中心或云服务器的Linux内核升级的传统做法是：

1. 将服务器上面的业务迁走
2. 将内核替换为新内核
3. 重启服务器，加载和运行升级后的内核
4. 最后再将业务迁到已经升级好内核的机器上面来

以上过程耗费的时间是比较长的。

**原地内核热升级技术** 机制探索直接原地快速地重启系统使用到的新内核，然后让业务迅速继续运行，整个过程相对更轻量、快捷。目前来看业界已经有一些技术探索，其核心总的来说为以下两点：**数据持久化存储** 和 **内核快速启动** 。前者容易理解，毕竟内核热升级，需要不中断业务执行，比如内核重启前，数据需要保存起来，重启过程中继续复用这部分数据，这部分难度不是太高，不是本课题的重点。本课题重点是后者，即出于业务的 downtime 时间要求考虑，通常情况下，很多关键业务downtime的时间是要求50～100ms，假设 OS 服务、业务应用层的状态恢复需要50ms，那么旧内核的shutdown、新内核的加载初始化必须要满足50ms以内，才能满足最终业务进程 downtime 50ms~100ms的要求。这个时间要求目前还没有任何一个技术/方案可以做到。

目前一个方案是如果第二个内核可以和第一个内核并行运行的话，第二个内核、系统服务初始化时，第一个内核继续运行，之后突然把第一个的多个进程状态、资源逐个切换到第二个内核，这样可以大大缩短downtime的时间。

这就是本项目期望实现的基于双内核的内核热升级方法。

```
          | ------------------------------------ |
          |     Kernel  A   |      Kernel B      |
          |--------------------------------------|
          |               hardware               |
          |--------------------------------------|
```

基本实现效果如下，两个 Terminal 对应了两个不同的内核，实现可同时与两个内核交互。

 <img src="https://www.dingmos.com/usr/uploads/2022/06/1614572930.png" width = "800" height = "300" alt="Kernel A and Kernel B" align=center />
 
 
 # Roadmap
 
 - [x] 环境搭建
  - [x] 编译 Linux4.19 与 Linux5.15 内核
  - [x] 构建使用 Linux5.15 内核的 ubuntu 虚拟机（debootstrap）
  - [x] busybox 构建根文件系统rootfs，作为第二个内核的 initramfs
- [x] kexec 机制学习研究
- [x] 双内核并存
  - [x] QEMU 启动虚拟机的时候为虚拟机配置两种交互方式：Console串口、VGA；
  - [x] 第一个内核执行kexec命令启动第二内核
    - [x] 第一内核为第二内核提前预留好后者能使用的资源（cpu和内存等）
    - [x] 第二内核启动时使用 initramfs 作为根文件系统
  - [x] kexec启动的第二内核正常启动完成初始化，此过程不停止第一内核的运行；
  - [x] 第一内核使用VGA串口，第二内核接管Console串口
- [ ] 资源接管
  - [ ] 第二内核接管第一内核的资源（物理核、内存、串口、进程状态等）
  - [ ] 下线第二内核
  - [ ] 数据测试
    - [ ] 测试第二内核启动的时间、启动后到接管资源成功的时间
    - [ ] 测试现有的先迁移数据、替换内核、迁回数据的方法所花费的时间，用于对比
- [ ] 扩展功能
  - [ ] 网卡接管
    - [ ] 使用带2张网卡的宿主机做上述实验
    - [ ] 第二内核启动完成后，接管包括网卡在内的共享资源
  - [ ] 双内核通信
    - [ ] 第一内核与第二内核之间借助如核间中断等方式互相通信


# 设计与实现

详细设计文档参考： [proj135-doc](https://gitlab.eduxiji.net/yart/proj135-doc)

![整体设计与实现](https://images-1258510704.cos.ap-guangzhou.myqcloud.com/img/20220602-image-20220602161021159.png)

1. kexec

利用 kexec 加载新内核

2. cpu hotplug 

利用 CPU 热插拔为新内核（TK）分配 CPU 资源，同时不影响原内核的运行

3. pci black list

PCI 设备黑名单机制，实现 TK 的硬件资源划分

# 如何运行

### qemu 启动

```bash
sudo qemu-system-x86_64 -kernel arch/x86/boot/bzImage \
    -smp 2 \
    --enable-kvm \
    -m 2G  \
    -hda ./tk/images/qemu-img-5G.img \
    -append "root=/dev/sda rw crashkernel=256M"   \
    -serial telnet:localhost:4321,server,nowait \
    -vga std
```


使用 virsh 启动，virsh 下虚拟机的[配置文件示例可见](_files/tk_kernel_boot.xml)

## kdump and crash

1. load crash kernel 

```bash

# kexec -p  /boot/bzImage --initrd=/boot/initrd.img  \
kexec -p  /boot/bzImage --initrd=/boot/rootfs.img  \
--append="console=ttyS0 disableapic twin_kernel nr_cpus=1 \ 
 acpi_irq_nobalance no_ipi_broadcast=1 rdinit=/linuxrc \
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
