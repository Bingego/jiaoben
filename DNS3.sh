请输入中国地区的公网地址的文件：zh_ipinfo.txt
Redirecting to /bin/systemctl restart  named.service
[root@servera ~]# cat cds2.sh
#!/bin/bash

#运行脚本获取中国地区的公网地址
#记录在zh_ipinfo.txt
read -p "请输入中国地区的公网地址的文件：" file
#截取中国电信的公网地址

awk -F"," 'BEGIN {print "acl zhdx {" };  $0 ~ /CHINANET/ {print $1"/"$2";"} ; END { print "};" }' $file > /etc/zhdx.cfg.back

sed '/^\/.*\|[A-Z]/d' /etc/zhdx.cfg.back > /etc/zhdx.cfg

#截取中国联通的公网地址
awk -F"," 'BEGIN {print "acl zhlt {" };  $0 !~ /CHINANET/ {print $1"/"$2";"} ; END { print "};" }' $file  > /etc/zhlt.cfg.back

sed '/^\/.*\|[A-Z]\|^[a-z].*;/d' /etc/zhlt.cfg.back > /etc/zhlt.cfg

#在主配置文件里定义外部文件的读取配置参数
sed -i '3iinclude "/etc/zhdx.cfg";\ninclude "/etc/zhlt.cfg";' /etc/named.conf
sed -i 's/match-clients { dx; };/\tmatch-clients { dx; zhdx; };/' /etc/named.conf
sed -i 's/match-clients { wt; };/\tmatch-clients { wt; zhlt; };/' /etc/named.conf



named-checkconf 
service named restart
