#!/bin/bash

#实验环境如下：

#解析的主机名称：www.abc.com

#电信客户端ip：172.25.22.11   希望其解析到结果为192.168.11.1

#网通客户端ip：172.25.22.12   希望其解析到结果为22.21.1.1

#其余剩下其他运营商的客户端解析的结果皆为1.1.1.1 

yum -y install bind bind-chroot &> /dev/null && echo "安装bind和bind-chroot成功"
#关闭防火墙
setenforce 0
iptables -F

#1）定义view字段

cat > /etc/named.conf << EOT
options {
	listen-on port 53 { 127.0.0.1; any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { localhost; any; };
	recursion no;
	dnssec-enable no;
	dnssec-validation no;
	dnssec-lookaside auto;
	bindkeys-file "/etc/named.iscdlv.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
view  dx {
        match-clients { 172.25.22.11; };
	zone "." IN {
		type hint;
		file "named.ca";
	};
	zone "abc.com" IN {
		type master;
		file "abc.com.dx.zone";	
	};
	include "/etc/named.rfc1912.zones";
};
view  wt {
        match-clients { 172.25.22.12; };
        zone "." IN {
                type hint;
                file "named.ca";
        };
        zone "abc.com" IN {
                type master;
                file "abc.com.wt.zone";
        };
	include "/etc/named.rfc1912.zones";
};
view  other {
        match-clients { any; };
        zone "." IN {
                type hint;
                file "named.ca";
        };
        zone "abc.com" IN {
                type master;
                file "abc.com.other.zone";
        };
        include "/etc/named.rfc1912.zones";
};
include "/etc/named.root.key";
EOT

#2）生成数据文件
cat > /var/named/abc.com.dx.zone << EOT
\$TTL 1D
@	IN SOA	ns1.abc.com. rname.invalid. (
					10	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
@	NS	ns1.abc.com.
ns1     A       172.25.22.10
www	A	192.168.11.1
EOT

cd /var/named/
cp abc.com.dx.zone abc.com.wt.zone

sed -i 's/www.*/www     A       22.21.1.1/' /var/named/abc.com.wt.zone

cp abc.com.wt.zone abc.com.other.zone

sed -i 's/www.*/www     A       1.1.1.1/' /var/named/abc.com.other.zone


chgrp named abc.com.*

#检测语法
named-checkconf

named-checkzone  abc.com /var/named/abc.com.dx.zone
named-checkzone  abc.com /var/named/abc.com.wt.zone 
named-checkzone  abc.com /var/named/abc.com.other.zone

#3）重启服务
service named start
chkconfig named on

