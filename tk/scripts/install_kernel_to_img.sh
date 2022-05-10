IMG=$1
MOUNT_POINT=mount-point.tmp
SCRIPTS_PATH="./tk/scripts/"

$SCRIPTS_PATH/mount-img.sh $IMG

sudo cp ./arch/x86/boot/bzImage $MOUNT_POINT/boot/
sudo cp ./tk/images/rootfs.img  $MOUNT_POINT/boot/
# sudo cp ../start_twin_kernel.sh mount-point.tmp/boot/

$SCRIPTS_PATH/umount-img.sh
