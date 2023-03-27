#!/bin/sh

echo -e "\nhello, busybox!\n"

mount -t proc none /proc
mount -t sysfs none /sys
# mount -t debugfs none /sys/kernel/debug

#----------- TURN eth0 UP (Optional)---------
#Enable eth0, when running with -device e1000,netdev=n3,mac=... the interface isn't UP
ifconfig eth0 up

sleep 5

echo -e "eth0 interface is: "
cat /sys/class/net/eth0/operstate
echo -e "\n"

ifconfig
#-------------------------------------------

echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\n"
 
sh