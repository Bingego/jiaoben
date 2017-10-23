#!/bin/bash

#使用sersync整合rsync,实现WEB页面同步更新,保证webserver的数据一致

#servera1  webserver(apache:80+rsyncd:873)  172.25.1.10
#serverb1  webserver(apache:80+rsyncd:873)  172.25.1.11
#serverc1  websrever(apache:80+rsyncd:873)  172.25.1.12

#sreverd1 发布页面代码 sersync+rsync客户端

yum -y install httpd &> /dev/null && echo"安装httpd成功"
yum -y install rsync &> /dev/null && echo"安装rsync成功"

cat > /etc/rsyncd.conf << EOT
uid = apache
gid = apache
use chroot = yes
max connections = 4
pid file = /var/run/rsyncd.pid
exclude = lost+found/
transfer logging = yes
timeout = 900
ignore nonreadable = yes
dont compress   = *.gz *.tgz *.zip *.z *.Z *.rpm *.deb *.bz2 *.iso

[webshare]
         path = /var/www/html
         comment = www.abc.com html page
         read only = no
         auth users=user01
         secrets file=/etc/rsyncd_user.db
EOT

echo "user01:123" >> /etc/rsyncd_user.db
chmod 600 /etc/rsyncd_user.db

#启动服务
rsync --daemon
echo "/usr/bin/rsync --daemon" >> /etc/rc.local
chmod +x /etc/rc.d/rc.local
pkill -9 rsync;rm -fr /var/run/rsyncd.pid
source  /etc/rc.local

netstat -tnlp |grep :873 &> /dev/null
chown apache.apache /var/www/html/
service httpd start
chkconfig httpd on

#同步数据到serverb和serverc
ssh root@172.25.22.11 "yum -y install httpd"
ssh root@172.25.22.11 "yum -y install rsync"

rsync -avzR /etc/rsyncd.conf root@172.25.22.11:/
rsync -avzR /etc/rsyncd_user.db root@172.25.22.11:/

ssh root@172.25.22.11 "rsync --daemon"
rsync -avzR /etc/rc.local root@172.25.22.11:/
ssh root@172.25.22.11 "chmod +x /etc/rc.d/rc.local"
ssh root@172.25.22.11 "pkill -9 rsync;rm -fr /var/run/rsyncd.pid"
ssh root@172.25.22.11 "source /etc/rc.local"

ssh root@172.25.22.11 "chown apache.apache /var/www/html/"
ssh root@172.25.22.11 "service httpd start"
ssh root@172.25.22.11 "chkconfig httpd on"




ssh root@172.25.22.12 "yum -y install httpd"
ssh root@172.25.22.12 "yum -y install rsync"

rsync -avzR /etc/rsyncd.conf root@172.25.22.12:/
rsync -avzR /etc/rsyncd_user.db root@172.25.22.12:/

ssh root@172.25.22.12 "rsync --daemon"
rsync -avzR /etc/rc.local root@172.25.22.12:/
ssh root@172.25.22.12 "chmod +x /etc/rc.d/rc.local"
ssh root@172.25.22.12 "pkill -9 rsync;rm -fr /var/run/rsyncd.pid"
ssh root@172.25.22.12 "source /etc/rc.local"

ssh root@172.25.22.12 "chown apache.apache /var/www/html/"
ssh root@172.25.22.12 "service httpd start"
ssh root@172.25.22.12 "chkconfig httpd on"








