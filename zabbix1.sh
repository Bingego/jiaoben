#!/bin/bash
# agent数据收集端 | servera | agent:172.25.1.10
# server服务端   |serverb |server:172.25.1.11
# web配置管理端   |serverc |web:172.25.1.12
# 数据保存数据库端 |serverd|database:172.25.1.13

#设置所有服务器的时区都是Asia/shanghai，分别在每台服务器上执行以下命令
for i in {10..13}
do
ssh root@172.25.22.$i "timedatectl set-timezone Asia/Shanghai ; ntpdate -u 172.25.254.254 ;  setenforce 0"
done

#server端通过源码编译的方式，将服务主目录放置/usr/local/zabbix目录下：
rpm -q lftp &>/dev/null
[ $? -ne 0 ]&& yum -y install lftp &> /dev/null && echo "安装lftp成功"
yum -y install expect &> /dev/null && echo "安装expect成功"

expect <<EOF &> /dev/null
spawn lftp 172.25.254.250:/notes/project/software/zabbix
expect ">"
send "mirror zabbix3.2/\r"
expect ">"
send "exit\r"
expect eof
EOF

cd zabbix3.2/
tar xf zabbix-3.2.7.tar.gz -C /usr/local/src/
yum install gcc gcc-c++ mariadb-devel libxml2-devel net-snmp-devel libcurl-devel -y &>/dev/null

# 安装源码编译需要的依赖包
cd /usr/local/src/zabbix-3.2.7/
./configure --prefix=/usr/local/zabbix --enable-server --with-mysql --with-net-snmp --with-libcurl --with-libxml2 --enable-agent --enable-ipv6 &>/dev/null
make && make install &>/dev/null

useradd zabbix
sed -i 's/DBHost=.*/DBHost=172.25.1.13/' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's/# DBPassword=.*/DBPassword=uplooking/' /usr/local/zabbix/etc/zabbix_server.conf

# Database端的安装
ssh root@172.25.22.13 "yum -y install mariadb-server mariadb" &>/dev/null
systemctl start mariadb

#登录上serverb这台服务器，将sql语句远程复制到数据库服务器上
scp -r /usr/local/src/zabbix-3.2.7/database/mysql/* 172.25.1.13:/root/

#mysql服务器将对应的sql语句进行导入的操作，三个sql文件的导入顺序不能出错
ssh root@172.25.22.13 "mysql"
ssh root@172.25.22.13 "delete from mysql.user where user='';"
ssh root@172.25.22.13 "update mysql.user set password=password('redhat') where user='root';"
ssh root@172.25.22.13 "create database zabbix;"
ssh root@172.25.22.13 "\q"

ssh root@172.25.22.13 "mysql zabbix < /root/schema.sql"
ssh root@172.25.22.13 "mysql zabbix < /root/images.sql"
ssh root@172.25.22.13 "mysql zabbix < /root/data.sql"

#mysql授权，授权给server端及web端
ssh root@172.25.22.13 "mysql"
ssh root@172.25.22.13 "grant all on zabbix.* to zabbix@'%' identified by 'uplooking';"
ssh root@172.25.22.13 "flush privileges;"
ssh root@172.25.22.13 " \q"

#Web端的安装
ssh root@172.25.22.12 "scp -r /root/zabbix3.2 172.25.22.12:/root/"
ssh root@172.25.22.12 "cd /root/zabbix3.2/"
ssh root@172.25.22.12 "yum -y install httpd php php-mysql &>/dev/null"
ssh root@172.25.22.12 "yum -y localinstall php-mbstring-5.4.16-23.el7_0.3.x86_64.rpm php-bcmath-5.4.16-23.el7_0.3.x86_64.rpm zabbix-web-3.2.7-1.el7.noarch.rpm zabbix-web-mysql-3.2.7-1.el7.noarch.rpm &>/dev/null" 

#变更web端相关配置文件，指定时区
ssh root@172.25.22.12 "sed -i 's/#php_value date.timezone.*/ php_value date.timezone Asia/Shanghai/'  /etc/httpd/conf.d/zabbix.conf"

ssh root@172.25.22.12 "systemctl restart httpd"

#启动所有相关服务软件
#server端的启动
cd /usr/local/zabbix/sbin/
./zabbix_server
netstat -tnlp |grep zabbix

