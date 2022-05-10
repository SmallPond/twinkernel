

## 1.KGDB简介

- Linux内核开发者使用最广泛的调试方法是printk方法，可是这种方法每次添加一些调试信息后还要从新编译烧写，效率不高
- Kgdb调试方法是一种源码级的Linux内核调试器。使用Kgdb调试内核时，须要结合gdb一块儿使用，使用他们能够对内核进行单步调试，设置断点，观察变量、寄存器的值等。
- 使用kgdb调试须要两台机器，即主机和目标机(通常为开发板)，主机上使用gdb经过串口或者网络来调试目标机，目标机上须要内核配置支持kgdb。



## 2.GDB配置

### 2.1 内核配置

```sh
# .config - Linux/x86 5.15.33 Kernel Configuration
Kernel hacking  --->
	Compile-time checks and compiler options  --->
		[*] Compile the kernel with debug info
        Generic Kernel Debugging Instruments  --->
        	[*] KGDB: kernel debugger  --->
        		<*>   KGDB: use kgdb over the serial console
    -*- Kernel debugging
    
# save 
```

重新编译内核

```
cd linux/
make -j nproc
```



### 2.2 qemu 启动命令

```sh
sudo qemu-system-x86_64 \
    -smp 2 \
    -m 2G  \
    -display none \
    -serial stdio \
    -nodefaults \
    -kernel /home/ubuntu/oscomp/twinkernel/arch/x86/boot/bzImage \
    -hda ./qemu-img-5G.img \
    -append "root=/dev/sda rw crashkernel=256M console=ttyS0 nokaslr nopti"   \
    -vnc :13 \
    -S -s
```

- **-s** 加到QEMU command line，把 **nokaslr nopti** 加到 kernel command line
  - 如果没有nokaslr nopti，gdb可能无法正确映射symbol addresses
- **-S** 表示“freeze CPU at start up”



### 2.4 GDB运行

进入GDB

```sh
# 安装gdb
$ sudo apt install gdb

# 启动gdb，读取vmlinux symbol & debugging message
$ gdb linux/vmlinux
(gdb) target remote :1234
(gdb) b virtblk_request_done
```

退出GDB

- 输入quit或者按下Ctrl-d退出



常用命令

| **命令**       |  **命令缩写**   | **命令说明**                                                 |
| -------------- | :-------------: | ------------------------------------------------------------ |
| list           |        l        | 显示多行源代码                                               |
| break          |        b        | 设置断点,程序运行到断点的位置会停下来                        |
| info           |        i        | 描述程序的状态                                               |
| run            |        r        | 开始运行程序                                                 |
| display        |      disp       | 跟踪查看某个变量,每次停下来都显示它的值                      |
| step           |        s        | 执行下一条语句,如果该语句为函数调用,则进入函数执行其中的第一条语句 |
| next           |        n        | 执行下一条语句,如果该语句为函数调用,不会进入函数内部执行(即不会一步步地调试函数内部语句) |
| print          |        p        | 打印内部变量值                                               |
| continue       |        c        | 继续程序的运行,直到遇到下一个断点                            |
| set var name=v |                 | 设置变量的值                                                 |
| start          |       st        | 开始执行程序,在main函数的第一条语句前面停下来                |
| file           | <img width=50/> | 装入需要调试的程序                                           |
| kill           |        k        | 终止正在调试的程序                                           |
| watch          |                 | 监视变量值的变化                                             |
| backtrace      |       bt        | 产看函数调用信息(堆栈)                                       |
| frame          |        f        | 查看栈帧                                                     |
| quit           |        q        |                                                              |
