
# launch one QEMU instance
qemu-system-x86_64 -m 512M \
				 -kernel linux-5.15.57/arch/x86/boot/bzImage \
				 -initrd initramfs.img \
                 -device e1000,netdev=n1,mac=52:54:00:12:34:56 \
                 -netdev socket,id=n1,mcast=230.0.0.1:1234 \
				 -enable-kvm \
				 -nographic \
				 -append "console=ttyS0 root=/dev/ram init=/init" \
				 -object filter-dump,id=f1,netdev=n1,file=dump1.dat \
				 > VM1.log &
				  
# launch another QEMU instance on same "bus"
qemu-system-x86_64 -m 512M \
				 -kernel linux-5.15.57/arch/x86/boot/bzImage \
				 -initrd initramfs.img \
                 -device e1000,netdev=n2,mac=52:54:00:12:34:57 \
                 -netdev socket,id=n2,mcast=230.0.0.1:1234 \
				 -enable-kvm \
				 -nographic \
				 -append "console=ttyS0 root=/dev/ram init=/init" \
				 -object filter-dump,id=f2,netdev=n2,file=dump2.dat \
				 > VM2.log &

# launch yet another QEMU instance on same "bus"
qemu-system-x86_64 -m 512M \
				 -kernel linux-5.15.57/arch/x86/boot/bzImage \
				 -initrd initramfs.img \
                 -device e1000,netdev=n3,mac=52:54:00:12:34:58 \
                 -netdev socket,id=n3,mcast=230.0.0.1:1234 \
				 -enable-kvm \
				 -nographic \
				 -append "console=ttyS0 root=/dev/ram init=/init" \
				 -object filter-dump,id=f3,netdev=n3,file=dump3.dat \
				 > VM3.log &


# # qemu-system-x86_64       -netdev socket,id=vlan0,mcast=230.0.0.1:1234 -device pcnet,id=eth0,netdev=vlan0,mac=56:34:12:00:54:08

#VM1 qemu-system-x86_64 -m 512M -kernel linux-5.15.57/arch/x86/boot/bzImage -initrd initramfs.img -device e1000,netdev=n1,mac=52:54:00:12:34:56 -netdev socket,id=n1,mcast=230.0.0.1:1234 -enable-kvm -nographic -append "console=ttyS0 root=/dev/ram init=/init" -object filter-dump,id=f1,netdev=n1,file=dump1.dat
#VM2 qemu-system-x86_64 -m 512M -kernel linux-5.15.57/arch/x86/boot/bzImage -initrd initramfs.img -device e1000,netdev=n2,mac=52:54:00:12:34:57 -netdev socket,id=n2,mcast=230.0.0.1:1234 -enable-kvm -nographic -append "console=ttyS0 root=/dev/ram init=/init" -object filter-dump,id=f2,netdev=n2,file=dump2.dat 
#VM3 qemu-system-x86_64 -m 512M -kernel linux-5.15.57/arch/x86/boot/bzImage -initrd initramfs.img -device e1000,netdev=n3,mac=52:54:00:12:34:58 -netdev socket,id=n3,mcast=230.0.0.1:1234 -enable-kvm -nographic -append "console=ttyS0 root=/dev/ram init=/init" -object filter-dump,id=f3,netdev=n3,file=dump3.dat 