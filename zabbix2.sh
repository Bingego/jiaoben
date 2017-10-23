#!/bin/bash
# zabbix变更中文环境
mysqldump zabbix > /tmp/zabbix.sql
sed -i 's/latin1/utf8/' /tmp/zabbix.sql 
mysqladmin drop zabbix
mysqladmin create database zabbix default charset utf8
mysql zabbix < /tmp/zabbix.sql 

#下载字体(楷体)
ssh root@172.25.22.12 "yum -y install wqy-microhei-fonts > /dev/null && echo "安装文泉驿成功""
ssh root@172.25.22.12 "wget ftp://172.25.254.250/notes/project/software/zabbix/simkai.ttf"
ssh root@172.25.22.12 "cp /root/simkai.ttf /usr/share/zabbix/fonts/"

ssh root@172.25.22.12 "sed -i 's/graphfont/simkai/' /usr/share/zabbix/include/defines.inc.php"

#安装agent端
ssh root@172.25.22.12 "scp -r 172.25.1.10:/root/zabbix3.2/ /root/"
ssh root@172.25.22.12 "cd /root/zabbix3.2/"
ssh root@172.25.22.12 "rpm -ivh zabbix-agent-3.2.7-1.el7.x86_64.rpm" 
ssh root@172.25.22.12 "yum -y install net-snmp net-snmp-utils"

#配置agent端相关参数
ssh root@172.25.22.10 "sed -i 's/^Server=.*/Server=172.25.1.11/' /etc/zabbix/zabbix_agentd.conf "
ssh root@172.25.22.10 "sed -i 's/^ServerActive=.*/ServerActive=172.25.1.11/' /etc/zabbix/zabbix_agentd.conf"
ssh root@172.25.22.10 "sed -i 's/^Hostname=.*/Hostname=servera.pod1.example.com/' /etc/zabbix/zabbix_agentd.conf"
ssh root@172.25.22.10 "sed -i 's/# UnsafeUserParameters=/UnsafeUserParameters=1/' /etc/zabbix/zabbix_agentd.conf"

ssh root@172.25.22.10 "systemctl start zabbix-agent"
ssh root@172.25.22.10 "systemctl enable zabbix-agent"

