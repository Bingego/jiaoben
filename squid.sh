#!/bin/bash

iptables -F
setenforce 0

#1，安装squid
yum install squid -y &> /dev/null && echo "安装squid成功"

#2,配置squid主配置文件
sed -i 's/http_access deny all/http_access allow all/' /etc/squid/squid.conf
sed -i 's/http_port 3128/http_port 3128 accel vhost vport/' /etc/squid/squid.conf
sed -i 's/#cache_dir ufs.*/cache_dir ufs \/var\/spool\/squid 256 16 256/' /etc/squid/squid.conf
cat >> /etc/squid/squid.conf << EOT
cache_peer 172.168.22.15 parent 8000 0 no-query originserver name=web
cache_peer_domain web web.cluster.com	--web.cluster.com
cache_peer_domain web 172.168.22.16
EOT

#3.启动squid服务
systemctl restart squid
netstat -tnpl |grep squid
