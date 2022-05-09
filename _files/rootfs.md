### 下载 ubuntu cloud image (推荐)

```

```

### 使用 qemu 制作镜像 （不推荐）

```
qemu-img create -f raw tk.img 10G
qemu-system-x86_64 --enable-kvm -m 2048 -smp 2 -hda tk.img -cdrom xxx.iso -boot dc

```

### 软件安装

暂时没有给 VM 配置访问外网的功能，给 VM 安装相关软件需要修改 img 

```bash
# 加载 nbd 内核模块，指定最大分区数
sudo modprobe nbd max_part=8
# 将 Image 
sudo qemu-nbd --connect=/dev/nbd0 bionic-server-cloudimg-amd64.img
# 查看 rootfs 对应的块
sudo fdisk /dev/nbd0 -l
# 创建 mount 点
mkdir /tmp/qcow2-mount/

# 挂载
sudo mount /dev/nbd0p1 /tmp/qcow2-mount/

# 操作完成后 umount 并断开 nbd 链接
umount /tmp/qcow2-mount/
sudo qemu-nbd --disconnect /dev/nbd0 

```