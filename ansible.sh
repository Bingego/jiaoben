#!/bin/bash
#安装Ansible

#下载软件，并安装
yum -y install lftp &> /dev/null && echo "安装lftp成功"
yum -y install expect &> /dev/null && echo "安装expect成功"

expect <<EOF &> /dev/null
spawn lftp 172.25.254.250:/notes/project/UP200/UP200_Ansible-master
expect ">"
send "mirror pkg/\r"
expect ">"
send "exit\r"
expect eof
EOF

setenforce 0
cd /root/pkg
yum -y localinstall *.rpm &>/dev/null && echo"安装Ansible成功"

# 配置Ansible
expect <<EOF &> /dev/null
spawn ssh-keygen
expect "(/root/.ssh/id_rsa):"
send "\r"
expect "(empty for no passphrase):"
send "\r"
expect "："
send "\r"
expect eof
EOF

#使用expect实现ssh传密码
expect << EOF > /dev/null 2>&1
spawn ssh-copy-id root@172.25.22.11
expect "no)?"
send "yes\r"
expect "password:"
send "uplooking\r"
expect "# "
send "setenforce 0"
send "exit\n"
expect eof
EOF

expect << EOF > /dev/null 2>&1
spawn ssh-copy-id root@172.25.22.12
expect "no)?"
send "yes\r"
expect "password:"
send "uplooking\r"
expect "# "
send "setenforce 0"
send "exit\n"
expect eof
EOF

#ansible的配置，配置主目录/etc/ansible
sed -i 's/private_key_file =.*/private_key_file = /root/.ssh/id_rsa/' /etc/ansible/ansible.cfg 

#定义inventory文件（定义主机组）
cat >> /etc/ansible/hosts << EOT
[webserver]
node1
node2
EOT

cat >> /etc/hosts << EOT
172.25.22.11 node1
172.25.22.12 node2
EOT

#测试（可以通过以下指令做简单的测试，具体操作后续分析）
ansible webserver -m ping
ansible webserver -m command -a "uptime"








