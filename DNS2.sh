#!/bin/bash

#ACL参数的配置

#1）在主配置文件里定义外部文件的读取配置参数
sed -i '1iinclude "/etc/dx.cfg";\ninclude "/etc/wt.cfg";' /etc/named.conf
sed -i 's/match-clients { 172.25.22.11; };/\tmatch-clients { dx; };/' /etc/named.conf
sed -i 's/match-clients { 172.25.22.12; };/\tmatch-clients { wt; };/' /etc/named.conf

#2）生成外部文件

cat > /etc/dx.cfg << EOT
acl "dx" {
        172.25.22.11;
        172.25.22.12;
};
EOT

cat > /etc/wt.cfg << EOT
acl "wt" {
        172.25.22.13;
        172.25.22.14;
};
EOT



#3)重启服务
named-checkconf
service named restart
