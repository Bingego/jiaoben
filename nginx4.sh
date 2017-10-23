#!/bin/bash

#Nginx 缓存
#nginx也可以作为一个缓存服务器存在,主要是针对一些经常被访问的页面进行缓存的操作,从而而减轻后端web服务器的压力

cat < /etc/nginx/nginx.conf << EOT
    proxy_temp_path /usr/share/nginx/proxy_temp_dir 1 2;
    proxy_cache_path /usr/share/nginx/proxy_cache_dir levels=1:2 keys_zone=cache_web:50m inactive=1d max_size=30g;

    upstream apache-servers {
        server 172.25.22.12:80 weight=1;
        server 172.25.22.13:80 weight=1;
}
EOT

mkdir -p /usr/share/nginx/proxy_temp_dir /usr/share/nginx/proxy_cache_dir
chown nginx /usr/share/nginx/proxy_temp_dir/ /usr/share/nginx/proxy_cache_dir/

cat > /etc/nginx/conf.d/www.proxy.com.conf << EOT
server {
    listen       80;
    server_name  www.proxy.com;
location / {
proxy_pass http://apache-servers;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
proxy_set_header X-Real-IP $remote_addr;
proxy_redirect off;
client_max_body_size 10m;
client_body_buffer_size 128k;
proxy_connect_timeout 90;
proxy_send_timeout 90;
proxy_read_timeout 90;
proxy_cache cache_web;
proxy_cache_valid 200 302 12h;
proxy_cache_valid 301 1d;
proxy_cache_valid any 1h;
proxy_buffer_size 4k;
proxy_buffers 4 32k;
proxy_busy_buffers_size 64k;
proxy_temp_file_write_size 64k;
}
}
EOT

service nginx restart
























