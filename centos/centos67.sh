#!/bin/bash
#Provided by @soeasy

PHP="5.6.32"
NGINX="2.2.1"
PCRE="8.36"
REDIS="3.2.11"
MYSQL="5.6.38"
PHP_REDIS="3.1.4"
PHP_YAF="2.3.5"
PHP_MEMCACHED="2.2.0"
PHP_MEMCACHE="3.0.8"

# yum update 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS6-Base-163.repo
yum clean all
yum makecache
echo "export PATH=\"\$PATH:/usr/local/mysql/bin/mysql:/usr/local/bin:\$PATH\";" >> /etc/profile
yum -y install telnet cmake ncurses-devel bison autoconf automake libtool gcc gcc-c++ openssl openssl-devel
#
# install php
yum -y install libxml2 libxml2-devel libcurl libcurl-devel freetype-devel libpng libmcrypt libjpeg-devel libpng-devel

cd /usr/local/src || exit 1
curl -L -o /usr/local/src/libmcrypt-2.5.8.tar.gz https://sourceforge.net/projects/mcrypt/files/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz/download
tar xzf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8 || exit 1
./configure && make && make install
#
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/php-${PHP}.tar.gz http://hk1.php.net/get/php-${PHP}.tar.gz/from/this/mirror
tar xzf php-${PHP}.tar.gz
cd php-${PHP} || exit 1
./configure --enable-ctype --enable-exif --enable-ftp --with-curl --with-zlib --with-mysql-sock=/tmp/mysql.sock --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --enable-mbstring --disable-debug --enable-sockets --disable-short-tags --enable-phar --enable-fpm --with-gd --with-openssl --with-mysql --with-mcrypt --enable-bcmath --with-iconv --enable-pcntl --enable-zip --enable-soap --enable-session
make && make install
#
cp ./sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf
chkconfig --add php-fpm
#
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/libmemcached-1.0.18.tar.gz https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz
tar xzf libmemcached-1.0.18.tar.gz
cd libmemcached-1.0.18 || exit 1
./configure
make && make install
#
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/yaf-${PHP_YAF}.tar.gz https://pecl.php.net/get/yaf-${PHP_YAF}.tgz
tar xzf yaf-${PHP_YAF}.tar.gz
cd yaf-${PHP_YAF} || exit 1
./configure
make && make install

## php -redis
/usr/local/bin/pecl install redis-${PHP_REDIS}
/usr/local/bin/pecl install memcached-${PHP_MEMCACHED}
/usr/local/bin/pecl install memcache-${PHP_MEMCACHE}

install tenginx
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/pcre-${PCRE}.tar.gz https://ftp.pcre.org/pub/pcre/pcre-${PCRE}.tar.gz
tar xzf pcre-${PCRE}.tar.gz
curl -L -o /usr/local/src/tengine-${NGINX}.tar.gz http://tengine.taobao.org/download/tengine-${NGINX}.tar.gz
tar xzf tengine-${NGINX}.tar.gz
cd tengine-${NGINX} || exit 1
./configure --with-select_module --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-http_ssl_module --with-pcre=/usr/local/src/pcre-${PCRE}
make && make install

## install redis
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/redis-${REDIS}.tar.gz http://download.redis.io/releases/redis-${REDIS}.tar.gz
tar xzf redis-${REDIS}.tar.gz
cd redis-${REDIS} || exit 1
make && make install
sh ./utils/install_server.sh
#
## install mysql
cd /usr/local/src || exit 1
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
curl -L -o /usr/local/src/mysql-${MYSQL}.tar.gz https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-${MYSQL}.tar.gz
tar xzf mysql-${MYSQL}.tar.gz
cd mysql-${MYSQL} || exit 1
cmake .
make && make install

cd /usr/local/mysql || exit 1
scripts/mysql_install_db --user=mysql
cp support-files/mysql.server /etc/init.d/mysql
chkconfig --add mysql
exit

echo "Creating /etc/init.d/nginx startup script"
(
cat <<'EOF'
#!/bin/bash
# nginx Startup script for the Nginx HTTP Server
# it is v.0.0.2 version.
# chkconfig: - 85 15
# description: Nginx is a high-performance web and proxy server.
#              It has a lot of features, but it's not for everyone.
# processname: nginx
# pidfile: /var/run/nginx.pid
# config: /usr/local/nginx/conf/nginx.conf
nginxd=/usr/local/nginx/sbin/nginx
nginx_config=/usr/local/nginx/conf/nginx.conf
nginx_pid=/var/run/nginx.pid
RETVAL=0
prog="nginx"
# Source function library.
. /etc/rc.d/init.d/functions
# Source networking configuration.
. /etc/sysconfig/network
# Check that networking is up.
[ ${NETWORKING} = "no" ] && exit 0
[ -x $nginxd ] || exit 0
# Start nginx daemons functions.
start() {
if [ -e $nginx_pid ];then
echo "nginx already running...."
exit 1
fi
echo -n $"Starting $prog: "
daemon $nginxd -c ${nginx_config}
RETVAL=$?
echo
[ $RETVAL = 0 ] && touch /var/lock/subsys/nginx
return $RETVAL
}
# Stop nginx daemons functions.
stop() {
     echo -n $"Stopping $prog: "
     killproc $nginxd
     RETVAL=$?
     echo
     [ $RETVAL = 0 ] && rm -f /var/lock/subsys/nginx /var/run/nginx.pid
}
# reload nginx service functions.
reload() {
 echo -n $"Reloading $prog: "
 #kill -HUP `cat ${nginx_pid}`
 killproc $nginxd -HUP
 RETVAL=$?
 echo
}
# See how we were called.
case "$1" in
start)
     start
     ;;
stop)
     stop
     ;;
reload)
     reload
     ;;
restart)
     stop
     start
     ;;
status)
     status $prog
     RETVAL=$?
     ;;
*)
     echo $"Usage: $prog {start|stop|restart|reload|status|help}"
     exit 1
esac
exit $RETVAL
EOF
) | tee /etc/init.d/nginx

chmod 775 /etc/rc.d/init.d/nginx
chkconfig --add nginx
reboot