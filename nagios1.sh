#!/bin/bash


#1） 下载软件，并安装nagios（rpm包）
yum -y install lftp &> /dev/null && echo "安装lftp成功"
yum -y install expect &> /dev/null && echo "安装expect成功"

expect <<EOF &> /dev/null
spawn lftp 172.25.254.250:/notes/project/UP200/UP200_nagios-master
expect ">"
send "mirror pkg/\r"
expect ">"
send "exit\r"
expect eof
EOF

setenforce 0
cd pkg/
yum localinstall *.rpm &> /dev/null && echo "安装nagios成功"

#2）使用用 htpasswd 工具设置 /etc/nagios/passwd 文文件,用用户名是 nagiosadmin,密码我们设置为 123
htpasswd -cmb /etc/nagios/passwd nagiosadmin 123  &> /dev/null && echo "设置nagiosadmin密码123成功"

#3）启动服务
systemctl restart httpd
systemctl start nagios



#配置监控本机的主配置文件
sed -i 's/alias                   localhost/alias                   nagios监控器/' /etc/nagios/objects/localhost.cfg
sed -i 's/address                 127.0.0.1/address                 172.25.22.10/' /etc/nagios/objects/localhost.cfg
sed -i 's/localhost/servera22/' /etc/nagios/objects/localhost.cfg
sed -i 's/notifications_enabled.*/notifications_enabled           1/' /etc/nagios/objects/localhost.cfg

#启动服务
nagios -v /etc/nagios/nagios.cfg &> /dev/null && echo "语法无误"
systemctl restart httpd
systemctl restart nagios
systemctl enable httpd
systemctl enable nagios







