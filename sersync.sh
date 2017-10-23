#!/bin/bash

#部署sersync服务
wget ftp://172.25.254.250/notes/project/software/sersync2.5.4_64bit_binary_stable_final.tar.gz
exit
tar xf sersync2.5.4_64bit_binary_stable_final.tar.gz -C /opt/
mv /opt/GNU-Linux-x86 /opt/sersync

sed -i 's/<<localpath watch=.*/<localpath watch="\/var/www/html">/' /opt/sersync/confxml.xml
sed -i 's/<remote ip=.*/ <remote ip="172.25.22.10" name="webshare"\/> \n<remote ip="172.25.22.11" name="webshare"\/> \n<remote ip="172.25.22.12" name="webshare"\/>/' /opt/sersync/confxml.xml
sed -i 's/<auth start=.*/<auth start="true" users="user01" passwordfile="/etc/rsyncd_user.db"\/>' /opt/sersync/confxml.xml

echo"123">/etc/rsyncd_user.db
chmod 600 /etc/rsyncd_user.db

#启动服务
/opt/sersync/sersync2 -d -r -o /opt/sersync/confxml.xml
