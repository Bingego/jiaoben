#!/bin/bash

#第一步：更改主机名，关闭seliunx，关闭eth0网卡，设置网关

sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0

sed -i 's/ONBOOT=yes/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '$a GATEWAY=192.168.0.10' /etc/sysconfig/network-scripts/ifcfg-eth1
service network restart && echo "启动网络成功"

#第二步: 下载软件，并安装
wget -r ftp://172.25.254.250/notes/project/software/cobbler_rhel7/
mv 172.25.254.250/notes/project/software/cobbler_rhel7/ cobbler

cd cobbler/
rpm -ivh python2-simplejson-3.10.0-1.el7.x86_64.rpm &> /dev/null
rpm -ivh python-django-1.6.11.6-1.el7.noarch.rpm python-django-bash-completion-1.6.11.6-1.el7.noarch.rpm &> /dev/null
yum localinstall cobbler-2.8.1-2.el7.x86_64.rpm cobbler-web-2.8.1-2.el7.noarch.rpm &> /dev/null

#第三步: 启动服务
systemctl restart cobblerd
systemctl restart httpd
systemctl enable httpd
systemctl enable cobblerd

#第四步：cobbler check 检测环境
sed -i 's/^server:.*/server: 192.168.0.11/' /etc/cobbler/settings
sed -i 's/^next_server:.*/next_server: 192.168.0.11/' /etc/cobbler/settings
#>激活tftp服务
sed -i 's/disable.*/disable=no/' /etc/xinetd.d/tftp
#>网络引导文件
yum -y install syslinux &> /dev/null && echo "安装syslinux成功"
#>启动同步
systemctl restart rsyncd &> /dev/null
systemctl enable rsyncd &> /dev/null
netstat -tnlp |grep :888 &> /dev/null && echo "rsync OK"

yum -y install pykickstart &> /dev/null

#>设置root密码
openssl passwd -1 -salt 'random-phrase-here' 'redhat'
sed -i 's/^default_password_crypted:.*/default_password_crypted: "$1$random-p$MvGDzDfse5HkTwXB2OLNb."'  /etc/cobbler/settings

#>安装fence设备
yum -y install fence-agents &> /dev/null && echo "安装fence-cobbler成功"

#第五步:导入镜像
mkdir /yum
mount -t nfs 172.25.254.250:/content /mnt/
mount -o loop /mnt/rhel7.2/x86_64/isos/rhel-server-7.2-x86_64-dvd.iso /yum/
cobbler import --path=/yum --name=rhel-server-7.2-base --arch=x86_64 &> /dev/null && echo "导入镜像成功"
cobbler distro list && echo "镜像列表"
cobbler profile list && echo "安装列表"

#第六步:修改dhcp，让cobbler来管理dhcp，并进行cobbler配置同步
yum -y install dhcp &> /dev/null && echo "安装dhcpd服务成功"

sed -i 's/192.168.1/192.168.0/g' /etc/cobbler/dhcp.template
sed -i 's/option routers.*/option routers             192.168.0.10;/' /etc/cobbler/dhcp.template
sed -i 's/option domain-name-servers 192.168.0.1;/option domain-name-servers 172.25.254.254;/' /etc/cobbler/dhcp.template 

#重启cobbler
sed -i 's/manage_dhcp:.*/manage_dhcp: 1/' /etc/cobbler/settings
systemctl restart cobblerd && echo "cobbler重启成功,进入数据通步cobbler sync"

#同步数据

# 执行生成密钥对 ssh-keygen (默认回车)
# 推送公钥root@localhost  
# --> ssh-copy-id root@localhost
ssh root@localhost "cobbler sync"
systemctl restart xinetd


















