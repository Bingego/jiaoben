#!/bin/bash

#rewrite应用举例：
#用户在访问www.joy.com 网站的news 目录时，我这个目录还在建设中，那么想要实现的就是用户访问该目录下任何一个文件，返回的都是首页文件，给用户以提示。

mkdir /usr/share/nginx/joy.com
mkdir /usr/share/nginx/joy.com/news
echo joy > /usr/share/nginx/joy.com/index.html
echo building > /usr/share/nginx/joy.com/news/index.html

cd /usr/share/nginx/joy.com/news/
touch new1.html
touch new2.html

cat > /etc/nginx/conf.d/www.joy.com.conf << EOT
server {
listen 80;
server_name www.joy.com;
#charset koi8-r;
#access_log /var/log/nginx/log/host.access.log main;
root /usr/share/nginx/joy.com;
index index.html index.htm;
location ~* /news/ {
rewrite ^/news/.* /news/index.html break;
}
}
EOT

service nginx restart



























