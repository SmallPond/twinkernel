## qemu VM 网络配置

```
sudo qemu-system-x86_64  \
    -smp 2 -m 2G  \
    --enable-kvm \
    -drive file=bionic-cloud.img\
    -serial mon:stdio  \
    -netdev tap,id=tapnet,ifname=tap0,script=no \
    -device e1000,netdev=tapnet \
    -display none
```

2. TAP 
```

tunctl -t tap0
ifconfig tap0 0.0.0.0 up
brctl addif virbr0 tap0
```