#!/bin/bash

# 虚拟主机:  www.test.com

#安装nginx
rpm -ivh ftp://172.25.254.250/notes/project/UP200/UP200_nginx-master/pkg/nginx-1.8.0-1.el7.ngx.x86_64.rpm &> /dev/null && echo "安装nginx成功"

setenforce 0
iptables -F

#启动nginx
systemctl start nginx

#修改虚拟主机配置
cat > /etc/nginx/conf.d/default.conf << EOT
server {
    listen       80;
    server_name  www.test.com;
    charset utf-8;
    access_log  /var/log/nginx/www.test.com.access.log  main;

    location / {
        root   /usr/share/nginx/test.com;
        index  index.html index.htm;
    }
 }
EOT

mkdir -p /usr/share/nginx/test.com
echo welcom to test.com > /usr/share/nginx/test.com/index.html
#ulimit -HSn 65535 && echo"解除限制（open file resource limit: 1024)"

nginx -t
#ps aux |grep nginx


service nginx reload
netstat -tnpl |grep nginx




















