#!/bin/bash


#1） 下载软件，并安装
yum -y install lftp &> /dev/null && echo "安装lftp成功"
yum -y install expect &> /dev/null && echo "安装expect成功"

expect <<EOF &> /dev/null
spawn lftp 172.25.254.250:/notes/project/UP200/UP200_cacti-master
expect ">"
send "mirror pkg/\r"
expect ">"
send "exit\r"
expect eof
EOF
setenforce 0

#2) 安装lamp
yum -y install httpd php php-mysql mariadb-server mariadb &> /dev/null && echo "安装lamp成功"

cd pkg/
expect <<EOF &> /dev/null
spawn yum localinstall cacti-0.8.8b-7.el7.noarch.rpm php-snmp-5.4.16-23.el7_0.3.x86_64.rpm
expect "[y/d/N]:"
send "y\r"
expect eof
EOF

#3).配置mysql数据库
service mariadb start

expect <<EOF &> /dev/null
spawn mysql
expect ">"
send "create database cacti;\r"
expect ">"
send "grant all on cacti.* to cactidb@'localhost' identified by '123456';\r"
expect ">"
send "flush privileges;\r"
expect ">"
send "exit\r"
expect eof
EOF
sed -i 's/$database_username =.*/$database_username = "cactidb";/' /etc/cacti/db.php
sed -i 's/$database_password = .*/$database_password = "123456";/' /etc/cacti/db.php

mysql -ucactidb -p123456 cacti < /usr/share/doc/cacti-0.8.8b/cacti.sql

#4) 配置cacti的相关参数
sed -i 's/Require host localhost/Require all granted/' /etc/httpd/conf.d/cacti.conf

#5） 配置php时区
timedatectl set-timezone Asia/Shanghai
 
sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/' /etc/php.ini

#6） 变更计划任务 --> 让其五分钟出一一次图####
sed -i 's/.//' /etc/cron.d/cacti 

#7)启动服务

service httpd restart
service snmpd start

service httpd enable
service snmpd enable 
netstat -anlp |grep :161
netstat -anpl |grep :80
netstat -anpl |grep snmp


#配置cacti监控本地服务器

sed -i 's/com2sec notConfigUser  default       public/com2sec notConfigUser  default       public/' /etc/snmp/snmpd.conf
sed -i '55i/view    systemview    included   .1/' /etc/snmp/snmpd.conf
service snmpd restart








