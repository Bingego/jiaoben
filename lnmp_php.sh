#!/bin/bash
yum -y install expect
expect <<EOF &> /dev/null
spawn lftp 172.25.254.250:/notes/weekend/UP200/UP200_nginx-master
expect ">"
send "mirror pkg/\r"
expect ">"
send "exit\r"
expect eof
EOF

#1.安装了spawn-fcgi，php 程序、数据库程序和php 连接数据库的驱动
cd pkg/

rpm -ivh nginx-1.8.1-1.el7.ngx.x86_64.rpm &> /dev/null && echo "安装nginx成功"
rpm -ivh spawn-fcgi-1.6.3-5.el7.x86_64.rpm &> /dev/null && echo "安装spawn-fcgi成功"
yum install -y php php-mysql mariadb-server &> /dev/null && echo "安装php php-mysql mariadb-server成功"

#2.配置虚拟主机
cat > /etc/nginx/conf.d/www.bbs.com.conf << EOT
server {
       listen 80;
       server_name www.bbs.com;
       root /usr/share/nginx/bbs.com;
       index index.php index.html index.htm;
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;   
 	    fastcgi_index index.php;
	    fastcgi_param SCRIPT_FILENAME /usr/share/nginx/bbs.com$fastcgi_script_name;
	    include fastcgi_params;
     }
}
EOT

mkdir /usr/share/nginx/bbs.com
systemctl start nginx.service

#3.配置spawn-fcg
cat >> /etc/sysconfig/spawn-fcgi << EOT
OPTIONS="-u nginx -g nginx -p 9000 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
EOT
systemctl start spawn-fcgi
systemctl enable spawn-fcgi

cat > /usr/share/nginx/bbs.com/test.php << EOT
<?php
  phpinfo();
?>
EOT

#4.数据库初始化
systemctl enable mariadb.service
systemctl start mariadb.service
mysqladmin -u root password "uplooking"

#5.创建网站根目录相关
expect <<EOF &> /dev/null
spawn lftp 172.25.254.250:/notes/project/software/lnmp
expect ">"
send "get Discuz_X3.1_SC_UTF8.zip\r"
expect ">"
send "exit\r"
expect eof
EOF

#安装Discuz网页
cp Discuz_X3.1_SC_UTF8.zip /tmp/
cd /tmp/
unzip Discuz_X3.1_SC_UTF8.zip
cp -r upload/* /usr/share/nginx/bbs.com/
chown nginx. /usr/share/nginx/bbs.com/ -R

#6.数据库授权

expect <<EOF &> /dev/null
spawn mysql -uroot -puplooking
expect ">"
send "select user,host,password from mysql.user;\r"
expect ">"
send "delete from mysql.user where user='';\r"
expect ">"
send "grant all on bbs.* to runbbs@'%' identified by 'uplooking';\r"
expect ">"
send "flush privileges;\r"
expect ">"
send "exit\r"
expect eof
EOF

启动服务：
service spawn-fcgi restart
systemctl restart nginx.service















