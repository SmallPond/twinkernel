## 

## 背景知识

- **BusyBox**

  - *BusyBox* 是一个集成了三百多个最常用Linux命令和工具的软件。简单的工具，例如ls、cat和echo等等，还包含了一些更大、更复杂的工具。
  - **linuxrc**的运行原理，在busybox的源码下/init/init.c有如下内容：
    - 表明linuxrc的作用和init一样，也就是执行linuxrc就是执行/sbin/init。busybox使用软链接将一个进程链接成多个进程，然后通过main函数args的第一个参数（也就是进程名）来区分具体执行哪一个，我们直接把文件名改为init其实就相当于执行了/sbin/init程序。
  - **根文件系统**（基于busybox制作**ramdisk根文件系统rootfs**）
    - 参考：[稀土掘金](https://juejin.cn/post/7024098720824164382)
    - 根文件系统是一种特殊的文件系统，特殊就在于它必须有**特定的目录结构以及特定的文件**，如下：
    - ![2.png](https://images-1258510704.cos.ap-guangzhou.myqcloud.com/img/20220509-bVJGo.png)

- ##### ramdisk

  - **内存盘**。从系统内存中，划出一部分当作硬盘使用。可以将应用程序，安装到ramdisk中，然后去执行。
    - ramdisk**并非是一个实际的文件系统**，而是一种将实际的文件系统转入内存的机制，因此可以作为根文件系统。
    - 实际上，ramdisk，使用的文件系统是**ext2**。(?)
  - 在linux中，ramdisk有2种：
    - initrd：linux内核2.0开始支持，大小固定
    - **initramfs**： linux内核2.4开始支持，大小可变

- **cpio** 

  - cpio是[UNIX](https://zh.m.wikipedia.org/wiki/UNIX)操作系统的一个文件[备份](https://zh.m.wikipedia.org/wiki/備份)程序及[文件格式](https://zh.m.wikipedia.org/wiki/檔案格式)。
  - cpio用于创建、解压归档文件，也可以对归档文件执行拷入拷出的动作，即向归档文件中追加文件，或从归档文件中提取文件。它也支持tar格式的归档文件

  

## BusyBox安装使用

### 1.下载安装

下载地址：https://busybox.net/downloads/

```sh
wget https://busybox.net/downloads/busybox-1.33.1.tar.bz2
```



### 2. 设置CPU架构

```
# 设置CPU架构
$ export ARCH=x86_64

# 设置交叉编译工具链前缀
$ export CROSS_COMPILE=x86_64-linux-gnu-

# 或者，
make CROSS_COMPILE=x86_64-linux-gnu- ARCH=x86_64 menuconfig
```



### 3.设置系统选项

```sh
# 生成默认.config
$ make  defconfig

# 设置busybox选项
$ make menuconfig

#修改选项
	···
	Settings  ---> 
    ...
    # 静态编译busybox
    --- Build Options  
    [*] Build static binary (no shared libs) 
    ...
	...

```

### 4. 编译安装

```
$ make -j nproc 
```

安装busybox，默认路径为当期目录的**_install**文件夹

```
make install
```



### 5.制作ramdisk根文件系统rootfs

基于busybox的文件系统启动过程：

`/sbin/init => /etc/inittab => /etc/init.d/rdS => /etc/fstab ...`



制作过程繁琐，可使用如下脚本：./creat_rootfs.sh

```sh
# 这些忘写到脚本里了，算了
cd busybox-1.33.1的父目录
mkdir qemu-image
vim creat_rootfs.sh
./creat_rootfs.sh
```

./creat_rootfs.sh的内容如下：

```sh
#!/bin/sh
busybox_folder="./busybox-1.33.1"
rootfs="rootfs"
echo $base_path
if [ ! -d $rootfs ]; then #判断文件是否存在
    mkdir $rootfs
fi
cp $busybox_folder/_install/* $rootfs/ -rf
cd $rootfs
if [ ! -d proc ] && [ ! -d sys ] && [ ! -d dev ] && [ ! -d etc/init.d ]; then
    mkdir proc sys dev etc etc/init.d
fi

if [ -f etc/init.d/rcS ]; then
    rm etc/init.d/rcS
fi
echo "#!/bin/sh" > etc/init.d/rcS
echo "mount -t proc none /proc" >> etc/init.d/rcS
echo "mount -t sysfs none /sys" >> etc/init.d/rcS
echo "/sbin/mdev -s" >> etc/init.d/rcS
chmod +x etc/init.d/rcS
if [ -f ../qemu-image/rootfs.img ]; then
    rm ../qemu-image/rootfs.img
fi
find . | cpio -o --format=newc > ../qemu-image/rootfs.img
```

此时rootfs/ 目录下保存着busybox生成的根文件系统内容，qemu-image/ 目录下的rootfs.img可被qemu使用。



### 6.启动QEMU

```sh
sudo qemu-system-x86_64 \
    -kernel /home/ubuntu/oscomp/twinkernel/arch/x86_64/boot/bzImage \
    -smp 2 \
    -m 2G  \
    -initrd /home/ubuntu/oscomp/qemu-image/rootfs.img \
    -append "rdinit=/linuxrc console=ttyS0 loglevel=8" \
    -serial stdio \
    -serial telnet:localhost:4321,server,nowait \
    -display none
```

