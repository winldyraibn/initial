#!/bin/bash
php_name=php-7.1.6
nginx_name=nginx-1.12.0
redis_name=redis-3.2.9
mysql_name=mysql-boost-5.7.18
zabbix_name=zabbix-3.2.6
dir_name=/usr/local
dir_tmp=/media

sed -n -e '1,/^exit 0$/!p' $0 > "${dir_tmp}/packages.tar.gz" 2>/dev/null

function f_yum(){
#############install require packages######################
echo "开始安装Yum依赖包"
sleep 3

         yum -y install system-tools development-tools libcap openssl098e libcap openssl098e ixgbe p7zip cname ibutils  ntp nmap \
                nmap-frontend sysstat zsh perl-libxml-perl perl-XML-SAXi bzip2-devel curl-devel libmcrypt libmcrypt-devel \
                perl-LDAP perl-Convert-ASN1 perl-DateManip perl-XML-Twig perl-XML-Grove perl-XML-Dumper perl-Digest-HMAC \
                perl-Crypt-SSLeay perl-XML-LibXML perl-XML-NamespaceSupport perl-Net-DNS perl-Net-IP \
                gdb dstat iperf lftp rlwrap smartmontools tcpdump  rsync python-setuptools lrzsz \
                perl-XML-Simple perl-FCGI perl-FCGI-ProcManager perl-GSSAPI perl-DBI perl-Authen-SASL \
                perl-Digest-SHA1 perl-Net-SMTP_auth perl-Net-Daemon perl-XML-SAX-Expat perl-Config-General

} #end f_yum

function f_mysql(){
###############install mysql##########################
echo "开始安装${mysql_name}"
sleep 3

groupadd mysql
useradd -r -g mysql mysql

mkdir -p /usr/local/mysql #新建mysql安装目录
mkdir -p /data/mysqldb    #新建mysql数据库数据文件目录

tar -zxvf $mysql_name.tar.gz
cd $mysql_name

#设置编译参数
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock -DDEFAULT_CHARSET=utf8 \
-DWITH_BOOST=boost -DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 \ 
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DMYSQL_DATADIR=/data/mysqldb \
-DMYSQL_TCP_PORT=3306 -DENABLE_DOWNLOADS=1 \

make &&make install

#将mysql目录得所有权交给mysql用户和mysql用户组
cd /usr/local/mysql/
chown -R mysql:mysql .

cd /data/mysqldb/
chown -R mysql:mysql .

#初始化mysql数据库
cd /usr/local/mysql/
./bin/mysql_install_db  --user=mysql --datadir=/data/mysqldb/ 
#即使是5.7 上述执行后还是报错
./bin/mysqld --initialize --user=mysql --datadir=/data/mysqldb/

#5.7初始化会自动生成一个初始化密码，一定要把密码给记住

#复制mysql服务启动配置文件
#需要进入到/etc/my.cnf 修改datadir=/data/mysqldb socket=/usr/local/mysql/mysql.sock 

#复制mysql服务启动脚本
cd /usr/local/mysql/
cp support-files/mysql.server /etc/init.d/mysqld

ln -s /usr/local/mysql/bin/mysql /usr/bin/
chkconfig --level 35 mysqld on

} #end f_mysql

function f_nginx(){
#############install nginx##################
echo "开始安装${nginx_name}"
sleep 3

tar zxvf ${nginx_name}.tar.gz

cd $nginx_name

./configure --prefix=$dir_name/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module

make&&make install

if [ $? -eq "0" ]; then	

	echo "install succeed"
else	
	echo "install failed"	

exit

fi

} #end f_nginx

function f_php(){

#############install php###################
echo "开始安装${php_name}"
sleep 3

tar zxvf $php_name.tar.gz

cd  $php_name 

./configure --prefix=$dir_name/php --with-config-file-path=/usr/local/php/etc --with-apxs2=/usr/local/apache2/bin/apxs --enable-fpm --enable-inline-optimization --disable-debug --disable-rpath --enable-shared  --enable-soap --with-libxml-dir --with-xmlrpc --with-openssl --with-mcrypt --with-mhash --with-pcre-regex --with-sqlite3 --with-zlib --enable-bcmath --with-bz2 --enable-calendar --with-curl --with-cdb --enable-dom --enable-exif --enable-fileinfo --enable-filter --with-pcre-dir --enable-ftp --with-gd --with-openssl-dir --with-jpeg-dir --with-png-dir --with-zlib-dir  --with-freetype-dir --enable-gd-native-ttf --with-gettext --with-gmp --with-mhash --enable-json --enable-mbstring --enable-mbregex --enable-mbregex-backtrack --with-libmbfl --with-onig --enable-pdo --with-mysqli --with-pdo-mysql --with-zlib-dir --with-pdo-sqlite --with-readline --enable-session --enable-shmop --enable-simplexml --enable-sockets  --enable-sysvmsg --enable-sysvsem --enable-sysvshm --enable-wddx --with-libxml-dir --with-xsl --enable-zip --enable-mysqlnd-compression-support --with-pear --enable-opcache

make&&make install

cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
cp -R ./sapi/fpm/php-fpm /etc/init.d/php-fpm

/etc/init.d/php-fpm

if [ $? -eq "0" ]; then	

	echo "install succeed"

else	

	echo "install failed"	

exit

fi

} #end f_php

function f_redis(){
echo "开始安装${redis_name}"
sleep 3

tar zxvf $redis_name.tar.gz
cd $redis_name

make&&make install

mkdir /usr/local/redis
mkdir -p /data/redis
mkdir /usr/local/redis/bin/

#执行安装脚本进行安装
cd utils/
./install_server.sh

} #end f_redis

function f_zabbix(){
echo "开始安装${zabbix_name}"
sleep 3

rpm -ivh zabbix-release-3.2-1.el6.noarch.rpm

groupadd zabbix
useradd -g zabbix zabbix


mysql -u root -pcactiuser<<EFO
create database zabbix character set utf8;
grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
flush privileges;
exit
EFO

tar zxvf $zabbix_name.tar.gz
cd $zabbix_name/database/mysql
mysql -uroot -pcactiuser zabbix <schema.sql
mysql -uroot -pcactiuser zabbix <images.sql
mysql -uroot -pcactiuser zabbix <data.sql

cd ../../
./configure --with-mysql --with-net-snmp --with-libcurl --enable-server --enable-agent --enable-proxy --prefix=/usr/local/zabbix
make install

mkdir /usr/local/nginx/www/zabbix
cp -r zabbix-3.2.6/frontends/php/* /usr/local/nginx/www/zabbix/

#拷贝服务启动脚本
cd $zabbix_name
cp misc/init.d/fedora/core/zabbix_* /etc/init.d/
chmod 755 /etc/init.d/zabbix_*
sed -i 's#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#g' /etc/init.d/zabbix_server
sed -i 's#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#g' /etc/init.d/zabbix_agentd

#配置zabbix服务端文件
sed -i 's#DBName=zabbix#DBName=zabbix#' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's#DBUser=zabbix#DBUser=zabbix#' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's#DBPassword=zabbix#DBPassword=zabbix#' /usr/local/zabbix/etc/zabbix_server.conf
sed -i '111s/# DBPassword=/DBPassword=zabbix/' /usr/local/zabbix/etc/zabbix_server.conf

#配置zabbix客户端文件 
sed -i 's/ServerActive=127.0.0.1/ServerActive='$hostip'/' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i 's#LogFile=/tmp/zabbix_agentd.log#LogFile=/var/log/zabbix/zabbix_agentd.log#g' /usr/local/zabbix/etc/zabbix_agentd.conf

#开启自定义KEY功能
sed -i '228s/# UnsafeUserParameters=0/UnsafeUserParameters=1/g' /usr/local/zabbix/etc/zabbix_agentd.conf
#Iclude=/usr/local/zabbix/zabbix_agentd.conf.d/ 自定的agentd文件可以写再这个目录
sed -i 's/# Include=\/usr\/local\/etc\/zabbix_agentd.conf.d\//Include=\/usr\/local\/zabbix\/etc\/zabbix_agentd.conf.d\//' /usr/local/zabbix/etc/zabbix_agentd.conf

mkdir /usr/local/zabbix/zabbix_agentd.conf.d

#开机启动
chkconfig zabbix_server on
chkconfig zabbix_agentd on
service zabbix_server start
service zabbix_agentd start

sed -i 's#;date.timezone =#date.timezone = 'Asia/Shanghai'#' /etc/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php.ini
sed -i 's/max_input_time = 60/max_input_time = 300/g' /etc/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 32M/g' /etc/php.ini
sed -i 's/memory_limit =128M/memory_limit = 128M/g' /etc/php.ini
sed -i 's/;mbstring.func_overload = 0/mbstring.func_overload = 2/g' /etc/php.ini
sed -i 's/;cgi.fix_pathinfo = 0/cgi.fix_pathinfo = 1/g' /etc/php.ini

sed -i '/$last = strtolower(substr($val, -1));/a$val = substr($val,0,-1);' /usr/local/nginx/www/zabbix/include/func.inc.php

killall php-fpm
/usr/local/php/sbin/php-fpm

} #end f_zabbix

HELP_TEXT="
程序版本: $VERSION 最后更新: $LAST_MODIFIED 维护人: 陈智刚
使用方法: ./nginx.sh [ 选项 ]
--yum
       安装yum包
--mysql
       安装mysql
--nginx
       安装nginx
--php
       安装php
--redis
       安装reis
--lnmp
       安装nginx+mysql+php
--zabbix
       安装zabbix
" #endhelp info

# pre check 
[ $# -eq 0 ] && echo "$HELP_TEXT" && exit 2
[ $# -ne 1 ] && echo '只支持单一选项.' && exit 3

OPTION=$1
case $OPTION in 
	--mysql)
	f_yum&&f_mysql
;;

	--nginx)
	f_yum&&f_nginx
;;

	--php)
	f_yum&&f_php
;;
	--redis)
	f_yum&&f_redis
;;
	--lnmp)
	f_yum&&f_nginx&&f_mysql&&f_php
;;
	--zabbix)
	f_zabbix
;;
esac
