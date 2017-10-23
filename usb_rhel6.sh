#!bin/bash

#基于rhel6的U盘系统

#1.格式化U盘
#清空分区表DPT

dd if=/dev/zero of=/dev/sda bs=500 count=1 &> /dev/null
fdisk $name <<EOF &> /dev/null
n
p
1


a
1
w
EOF

partx -a /dev/sda

mkfs.ext4 /dev/sda1 &> /dev/null
mkdir -p /mnt/usb

mount /dev/sda1  /mnt/usb/

#搭建yum源
cat > /etc/yum.repos.d/base.repo << EOT
[base]
baseurl=http://172.25.254.254/content/rhel6.5/x86_64/dvd
gpgcheck=0
EOT

#2. 安装文件系统
yum -y install filesystem --installroot=/mnt/usb/ &> /dev/null

#3. 安装应用程序与bash shell
yum -y install bash coreutils findutils grep vim-enhanced rpm yum passwd net-tools util-linux lvm2 openssh-clients bind-utils --installroot=/mnt/usb/ &> /dev/null

#4.安装内核
cp -a /boot/vmlinuz-2.6.32-431.el6.x86_64 /mnt/usb/boot/
cp -a /boot/initramfs-2.6.32-431.el6.x86_64.img /mnt/usb/boot/
cp -arv /lib/modules/2.6.32-431.el6.x86_64/ /mnt/usb/lib/modules/ &> /dev/null

#5 安装grub软件
rpm -ivh http://172.25.254.254/content/rhel6.5/x86_64/dvd/Packages/grub-0.97-83.el6.x86_64.rpm --root=/mnt/usb/ --nodeps --force

grub-install  --root-directory=/mnt/usb/ /dev/sda --recheck

#修改相关的配置文件(fstab grub.conf)中的UUID
cp /boot/grub/grub.conf  /mnt/usb/boot/grub/

uuid=$(blkid /dev/sda1 | grep -Eo '(.){8}-((.){4}-){3}(.){12}')
sed -i -r "s/(.){8}-((.){4}-){3}(.){12}/$uuid/g" /mnt/usb/etc/fstab  /mnt/usb/boot/grub/grub.conf

#6 完善配置文件
cp /etc/skel/.bash* /mnt/usb/root/
cat > /mnt/usb/etc/sysconfig/network << EOT
NETWORKING=yes
HOSTNAME=myusb.hugo.org
EOT

cp /etc/sysconfig/network-scripts/ifcfg-eth0 /mnt/usb/etc/sysconfig/network-scripts/
cat > /mnt/usb/etc/sysconfig/network-scripts/ << EOT
DEVICE="eth0"
BOOTPROTO="static"
ONBOOT="yes"
IPADDR=192.168.0.8
NETMASK=255.255.255.0
GATEWAY=192.168.0.254
DNS1=8.8.8.8
EOT

#设置密码
expect <<EOF > /dev/null 2>&1
spawn grub-md5-crypt
expect "rd:"
send "123\r"
expect "rd:"
send "123\r"
expect eof
EOF

umount /mnt/usb/




















