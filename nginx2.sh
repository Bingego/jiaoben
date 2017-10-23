#!/bin/bash

#加密连接https
#设置（购买） CA机构证书
#通过CA机构的证书 ，生成网页的密钥对（私钥与公钥[证书]）

#环境:serverb作为CA中心,servera作为nginx配置ssl⻚页面面的web服务端

#1)servera上创建私钥

mkdir /etc/nginx/key
cd /etc/nginx/key/
openssl genrsa 2048 > servera-web.key

#2)生成证书颁发请求
expect <<EOF &> /dev/null
spawn openssl req -new -key servera-web.key -out servera-web.csr
expect "[XX]:"
send "CN\r"
expect "[]:"
send "GD\r"
expect "[Default City]:"
send "GZ\r"
expect "[Default Company Ltd]:"
send "UPLOOKING\r"
expect "[]:"
send "IT\r"
expect "[]:"
send "www.uplooking.com\r"
expect "[]:"
send "web@uplooking.com\r"
expect "[]:"
send "\r"
expect "[]:"
send "\r"
expect eof
EOF

#3)将证书颁发请求提交给CA中心(serverb模拟成CA中心)
expect <<EOF &> /dev/null
scp servera-web.csr 172.25.22.11:~
expect "no)?"
send "yes\r"
expect "password:"
send "uplooking\r"
expect eof
EOF

expect <<EOF &> /dev/null
spawn ssh root@serverb22
expect "no)?"
send "yes\r"
expect "password:"
send "uplooking\r"
expect eof
EOF

#4) serverb模拟成CA,执行行自自签名操作
setenforce 0

expect <<EOF &> /dev/null
spawn openssl genrsa -des3 -out ca.key 4096
expect "ca.key:"
send "redhat\r"
expect "ca.key:"
send "redhat\r"
expect eof
EOF

expect <<EOF &> /dev/null
spawn openssl req -new -x509 -days 3650 -key ca.key -out ca.crt
expect "ca.key:"
send "redhat\r"
expect "[XX]:"
send "CN\r"
expect "[]:"
send "GD\r"
expect "[Default City]:"
send "GZ\r"
expect "[Default Company Ltd]:"
send "\r"
expect "[]:"
send "\r"
expect "[]:"
send "ca.uplooking.com\r"
expect "[]:"
send "\r"
expect eof
EOF

#5)CA中心针对证书颁发请求创建证书

expect <<EOF &> /dev/null
openssl x509 -req -days 365 -in servera-web.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out servera-web.crt
expect "ca.key:"
send "redhat\r"
expect eof
EOF

#6）证书回传给web服务与客户端

expect <<EOF &> /dev/null
scp servera-web.crt 172.25.1.10:/etc/nginx/key/
expect "no)?"
send "yes\r"
expect "password:"
send "uplooking\r"
expect eof
EOF

#7） ssl的配置
cat > /etc/nginx/conf.d/uplooking.com.conf  << EOT
server {
    listen       443 ssl;  # https监听443端口
    server_name  www.uplooking.com; 

    ssl_certificate      /etc/nginx/key/servera-web.crt;  #证书存放位置
    ssl_certificate_key  /etc/nginx/key/servera-web.key;  #私钥存放位置

    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout  5m;

    ssl_ciphers  HIGH:!aNULL:!MD5;    
#指出允许的密码，密码指定为openssl支持的格式
    ssl_prefer_server_ciphers   on;
#依赖SSLv3 和TLSv1 协议的服务器密码将优先于客户端密码
        root   /usr/share/nginx/uplooking.com;  #定义网站根目录相关
        index  index.html index.htm;
}
EOT

mkdir -p /usr/share/nginx/uplooking.com
echo ssl > /usr/share/nginx/uplooking.com/index.html
systemctl reload nginx
netstat -tnpl |grep nginx











































