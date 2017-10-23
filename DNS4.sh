#!/bin/bash

# 基于dns-view的主辅同步
#实验环境里，我们以serverj作为我们的dns从服务器，servera作为我们的dns主服务器


#ip地址对应关系如下：
#servera: eth0:172.25.22.10 eth1:192.168.1.10 eth2:192.168.1.10
#serverj: eth0:172.25.22.19 eth1:192.168.1.19 eth2:192.168.1.19 


sed -i 's/match-clients { dx; zhdx; };/\tmatch-clients { dx; zhdx; 172.25.22.19; !192.168.0.19; !192.168.1.19; };/' /etc/named.conf
sed -i 's/match-clients { wt; zhlt; };/\tmatch-clients { wt; zhlt; !172.25.22.19; 192.168.0.19; !192.168.1.19; };/' /etc/named.conf
sed -i 's/match-clients { any; };/\tmatch-clients { any; !172.25.22.19; !192.168.0.19; 192.168.1.19; };/' /etc/named.conf

named-checkconf
service named restart

#将配置文件从servera迁移至serverj
tar czvf /tmp/dns_config.tar.gz /etc/dx.cfg /etc/wt.cfg /etc/zhdx.cfg /etc/zhlt.cfg  /etc/named.conf 

expect <<EOF &> /dev/null
spawn scp /tmp/dns_config.tar.gz serverj22:/root/
expect "no)?"
send "yes\r"
expect "password:"
send "uplooking\r"
expect eof
EOF

#从servera远程到serverj

expect <<EOF &> /dev/null
spawn ssh root@serverj22
expect "no)?"
send "yes\r"
expect "password:"
send "uplooking\r"
expect eof
EOF

setenforce 0
yum -y install bind
#解压
tar xf dns_config.tar.gz -C /

cat > /etc/named.conf << EOT
include "/etc/dx.cfg";
include "/etc/wt.cfg";
include "/etc/zhdx.cfg";
include "/etc/zhlt.cfg";
options {
        listen-on port 53 { 127.0.0.1; any; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
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
        match-clients { dx; zhdx; 172.25.22.19; !192.168.0.19; !192.168.1.19; };
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
        match-clients { wt; zhlt; !172.25.22.19; 192.168.0.19; !192.168.1.19; };
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
        match-clients { any; !172.25.22.19; !192.168.0.19; 192.168.1.19; };
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

#sed -i 's/master/slave/g' /etc/named.conf
#sed -i 's/file "abc.com.dx.zone";/\tfile "slaves/abc.com.dx.zone";/' /etc/named.conf
#sed -i 's/file "abc.com.wt.zone";/\t file "slaves/abc.com.wt.zone";/' /etc/named.conf
#sed -i 's/file "abc.com.other.zone";/\t file "slaves/abc.com.other.zone";/' /etc/named.conf

#启动服务
service named start
ls /var/named/slaves/ -l
chkconfig named on



















