#!/bin/bash

#1.安装jdk，tomcat本身是由java语言开发出来，需要有java虚拟机的环境才能够正常运行。
lftp 172.25.254.250:/notes/project/UP200/UP200_tomcat-master
mirror pkg/ &> /dev/null
exit
wget ftp://172.25.254.250:/notes/project/software/tomcat/ejforum-2.3.zip

cd pkg/
tar xf jdk-7u15-linux-x64.tar.gz -C /opt/
mv /opt/jdk1.7.0_15/ /opt/java

#2.安装tomcat
mkdir /usr/local/tomcat
tar -xf apache-tomcat-8.0.24.tar.gz -C /usr/local/tomcat

#3.jsvc的方式启动
#采用root+tomcat用户的方式启动服务。
#root用户负责监听端口号。tomcat用户处理实际请求，该过程中需要有tomcat用户。

#1）生成tomcat用户（uid，gid可随意指定，一般在rhel7版本中选择1-1000中未被占用的一个数字）
cd/usr/local/tomcat/
groupadd -g 888 tomcat  
useradd -g 888 -u 888 tomcat -s /sbin/nologin
tar -czf - apache-tomcat-8.0.24/ | tar -xzf - -C /home/tomcat/

#2）编译安装jsvc文件，并将jsvc文件存放至tomcat服务主目录下的bin目录下
cd /home/tomcat/apache-tomcat-8.0.24/bin
tar -xf commons-daemon-native.tar.gz

cd commons-daemon-1.0.15-native-src/unix/
yum -y install gcc &> /dev/null && echo "安装gcc成功"
./configure  --with-java=/opt/java &> /dev/null
make &> /dev/null

cp jsvc /home/tomcat/apache-tomcat-8.0.24/bin/

#3）优化tomcat命令，jsvc的方式启动实际执行的脚本为bin目录下的daemon.sh
cd /home/tomcat/apache-tomcat-8.0.24/bin/
cp daemon.sh /etc/init.d/tomcat

sed -i '2i\# chkconfig: 2345 20 10' /etc/init.d/tomcat
sed -i '22a\CATALINA_HOME=/home/tomcat/apache-tomcat-8.0.24\nCATALINA_BASE=/home/tomcat/apache-tomcat-8.0.24\nJAVA_HOME=/opt/java/' /etc/init.d/tomcat

#启动tomcat
chkconfig --add tomcat
chkconfig tomcat on

#4）运用jsvc的方式启动tomcat

chown tomcat. -R /home/tomcat/apache-tomcat-8.0.24/
service tomcat start
ps -ef | grep tomcat
#**可以看到该方式启动了两个进程，一个进程root拥有，另一个进程由tomcat拥有**


#4.3.TOMCAT的重点配置
#1）配置tomcat的虚拟主机,修改tomcat的主配置文件，server.xml配置文件

sed -i 's/<Host name=.*/<Host name="www.jsp.com"  appBase="jsp.com"' /home/tomcat/apache-tomcat-8.0.24/conf/server.xml

service tomcat stop
service tomcat start

#2）将网页文件放置网站根目录下
mkdir -p /home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT/
cp -r /home/tomcat/ejforum-2.3.zip /tmp
cd /tmp
unzip ejforum-2.3.zip
cp ejforum-2.3/ejforum/* -r /home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT/

#3）配置和数据库的连接
cd pkg
tar -xf mysql-connector-java-5.1.36.tar.gz -C /tmp
cp /tmp/mysql-connector-java-5.1.36/mysql-connector-java-5.1.36-bin.jar /home/tomcat/apache-tomcat-8.0.24/lib/ 

sed -i 's/<!-- DB Connection Pool - Hsqldb.*/<!-- DB Connection Pool - Hsqldb' /home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT/WEB-INF/conf/config.xml
sed -i 's/sqlAdapter="sql.HsqldbAdapter"\/>/sqlAdapter="sql.HsqldbAdapter"\/> -->' /home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT/WEB-INF/conf/config.xml
sed -i 's/<!-- DB Connection Pool - Mysql.*/<!-- DB Connection Pool - Mysql -->' /home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT/WEB-INF/conf/config.xml

sed -i 's/username="sa" password=""/ username="javabbs" password="uplooking"' /home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT/WEB-INF/conf/config.xml

sed -i 's/url="jdbc:mysql.*/ url="jdbc:mysql://localhost:3306/javabbs?characterEncoding=gbk&amp;autoReconnect=true&amp;autoReconnectForPools=true&amp;zeroDateTimeBehavior=convertToNull"' /home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT/WEB-INF/conf/config.xml

#4）配置数据库服务器
yum -y install mariadb-server
systemctl restart mariadb
mysqladmin create javabbs
cd /tmp/ejforum-2.3/install/script
mysql javabbs < easyjforum_mysql.sql 

mysql
grant all on javabbs.* to javabbs@'localhost' identified by 'uplooking';
grant all on javabbs.* to javabbs@'servera.pod0.example.com' identified by 'uplooking'; # 授权
flush privileges;
exit

#5）启动服务
setenforce 0
service tomcat stop
service tomcat start











