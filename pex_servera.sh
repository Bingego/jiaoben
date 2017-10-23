#!/bin/bash

#配置servera 路由器
cat >> /etc/sysctl.conf << EOT
net.ipv4.ip_forward = 1
EOT
sysctl -p
cat /proc/sys/net/ipv4/ip_forward

iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -j SNAT --to-source 172.25.22.10 && echo "添加防火墙策略成功"
