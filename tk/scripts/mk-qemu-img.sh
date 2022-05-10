IMG=$1
SIZE=$2

DIR=mount-point.dir
qemu-img create $IMG ${SIZE}
mkfs.ext2 $IMG
mkdir $DIR

# 以 loop mount 方式挂载，img 中包含了文件系统
sudo mount -o loop $IMG $DIR

# sudo debootstrap --arch=amd64 --variant=minbase bionic $DIR  http://mirrors.aliyun.com/ubuntu/  
sudo debootstrap --arch=amd64  bionic  $DIR  http://mirrors.aliyun.com/ubuntu/
sudo umount $DIR
rmdir $DIR
