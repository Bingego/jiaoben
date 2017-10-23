#!/bin/bash

#nagios添加多实例serverb
cp /etc/nagios/objects/localhost.cfg /etc/nagios/objects/serverb22.cfg

sed -i 's/alias                   nagios监控器/alias                   nagios监控器2/' /etc/nagios/objects/serverb22.cfg
sed -i 's/address                 172.25.22.10/address                 172.25.22.11/' /etc/nagios/objects/serverb22.cfg
sed -i 's/servera22/serverb22/' /etc/nagios/objects/serverb22.cfg
sed -i '46,50s/^/#/' /etc/nagios/objects/serverb22.cfg
#sed -i 's/notifications_enabled.*/notifications_enabled           1/' /etc/nagios/objects/serverb22.cfg

#远程修改主配置文件
sed -i '39icfg_file=\/etc\/nagios\/objects/serverb22.cfg' /etc/nagios/nagios.cfg

#启动服务
nagios -v /etc/nagios/nagios.cfg &> /dev/null && echo "语法无误"
systemctl restart nagios
systemctl enable nagios
