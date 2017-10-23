#!/bin/bash

#lamp的自动部署
yum install php php-mysql mariadb-server -y &> /dev/null
yum -y install httpd &> /dev/null

mkdir -p /home/ansible/
cp /etc/httpd/conf/httpd.conf /tmp

mkdir -p /home/ansible/file
cp /tmp/httpd.conf /home/ansible/file/
cp /etc/my.cnf /home/ansible/file/
sed -i 's/socket=.*/socket=/var/tmp/mysql.sock/' /home/ansible/file/my.cnf

#配置php时区
cp /etc/php.ini /home/ansible/file/
sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/' /home/ansible/file/php.ini

echo "test page" > /home/ansible/file/test.html

关闭防火墙
iptables -F
setenforce 0

cat > /home/ansible/lamp.yml <<EOT
- hosts: webserver
  remote_user: root
  tasks:
  - name: install httpd
    yum: name=httpd state=present
  - name: install mysql-server
    yum: name=mariadb-server state=present
  - name: install php
    yum: name=php state=present
  - name: httpd conf
    copy: src=/home/ansible/file/httpd.conf dest=/etc/httpd/conf/httpd.conf mode=644
  - name: mysql conf
    copy: src=/home/ansible/file/my.cnf dest=/etc/my.cnf mode=644
  - name: php conf
    copy: src=/home/ansible/file/php.ini dest=/etc/php.ini mode=644
    notify:
    - start mysql
    - start httpd
  - name: service status
    shell: netstat -tnlpa |grep -E '(mysqld|httpd)' > /tmp/lamp.status
  - name: get lamp.status
    fetch: src=/tmp/lamp.status dest=/tmp/
  - name: test page
    copy: src=/home/ansible/file/test.html dest=/var/www/html/test.html

  handlers:
    - name: start mysql
      service: name=mariadb state=started
    - name: start httpd
      service: name=httpd state=started
    - name: service status
      shell: netstat -tnlpa |grep -E '(mysqld|httpd)' > /tmp/lamp.status
EOT

#执行剧本
cd /home/ansible/
ansible-playbook --check lamp.yml &> /dev/null
ansible-playbook lamp.yml &>/dev/null

#测试
ansible webserver -m uri -a 'url=http://172.25.22.17/test.html'























