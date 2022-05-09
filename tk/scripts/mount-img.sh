IMG=$1
DIR=mount-point.tmp

mkdir $DIR
sudo mount -o loop $IMG $DIR
