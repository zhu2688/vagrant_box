#!/bin/bash
#Provided by @soeasy

PHP="7.2.19"
NGINX="2.3.0"
PCRE="8.36"
REDIS="4.0.14"
MAIN_MYSQL="5.6"
MYSQL="5.6.44"
LIB_FREETYPE='2.6.4'
LIB_ZIP="1.5.2"
LIB_GD="2.2.5"
CMAKE='3.7.2'
COMPOSER="1.8.5"
PHP_JPEG='9b'
PHP_REDIS="4.1.1"
PHP_YAF="3.0.8"
PHP_YAR="2.0.5"
PHP_MSGPACK="2.0.3"
PHP_MONGODB="1.5.3"
PHP_APCU="5.1.17"
CACHETOOL="4.0.1"
COUNTRY="CN"
COUNTRY_FILE="/tmp/country"
WWWUSER="www"
MYSQLUSER="mysql"
PHP_INI="/etc/php.ini"
PHP_SERVER="php.net"

groupadd $WWWUSER
useradd -r -g $WWWUSER -s /sbin/nologin -g $WWWUSER -M $WWWUSER
# yum update 
# check country
curl -o $COUNTRY_FILE ifconfig.co/country-iso
checkCN=$(< $COUNTRY_FILE grep $COUNTRY)

if [[ -n $checkCN ]]; then
  if [[ -f /usr/local/qcloud ]]; then
      curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos6_base.repo
      curl -o /etc/yum.repos.d/epel.repo http://mirrors.cloud.tencent.com/repo/epel-6.repo
  elif [ -f /usr/sbin/aliyun-service ]; then
      curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
      curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
  else
      curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS6-Base-163.repo
  fi
  PHP_SERVER="cn2.php.net"
fi

yum clean all
yum makecache
/bin/sed -i -e '/^export.*mysql\/bin.*$/d' /etc/profile
echo "export PATH=\"/usr/local/cmake/bin/:/usr/local/mysql/bin:/usr/local/bin:\$PATH\";" >> /etc/profile
echo '/usr/local/lib64' >> /etc/ld.so.conf
#shellcheck disable=SC1091
source /etc/profile
ldconfig

# update git -> 2.* 
# yum install http://opensource.wandisco.com/centos/6/git/x86_64/wandisco-git-release-6-1.noarch.rpm
# update gcc -> gcc 4.8.2
curl -o /etc/yum.repos.d/hop5.repo http://www.hop5.in/yum/el6/hop5.repo
yum -y install epel-release telnet git wget cmake ncurses-devel bison autoconf automake libtool gcc gcc-c++ openssl openssl-devel curl-devel geoip-devel
killall php-fpm
killall mysql
killall nginx
# install lib devel
yum -y install libxml2 libxml2-devel libcurl libcurl-devel freetype-devel libpng libjpeg-devel libpng-devel libwebp-devel

# install cmake 
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/cmake-${CMAKE}.tar.gz https://cmake.org/files/v3.7/cmake-${CMAKE}.tar.gz
tar xzf cmake-${CMAKE}.tar.gz
cd cmake-${CMAKE} || exit 1
./configure && make && make install

# install libzip 
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/libzip-${LIB_ZIP}.tar.gz https://nih.at/libzip/libzip-${LIB_ZIP}.tar.gz
tar xzf libzip-${LIB_ZIP}.tar.gz
cd libzip-${LIB_ZIP} || exit 1
mkdir -p build 
cd build && cmake .. && make && make install

# install freetype
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/freetype-${LIB_FREETYPE}.tar.gz https://download.savannah.gnu.org/releases/freetype/freetype-${LIB_FREETYPE}.tar.gz
tar xzf freetype-${LIB_FREETYPE}.tar.gz
cd freetype-${LIB_FREETYPE} || exit 1
./configure && make && make install

# install libjpeg
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/jpegsrc.v${PHP_JPEG}.tar.gz http://www.ijg.org/files/jpegsrc.v${PHP_JPEG}.tar.gz
tar xzf jpegsrc.v${PHP_JPEG}.tar.gz
cd jpeg-${PHP_JPEG} || exit 1
./configure && make && make install
make libdir=/usr/lib64
make libdir=/usr/lib64 install

# install libgd
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/libgd-${LIB_GD}.tar.gz https://github.com/libgd/libgd/releases/download/gd-${LIB_GD}/libgd-${LIB_GD}.tar.gz
tar xzf libgd-${LIB_GD}.tar.gz
cd libgd-${LIB_GD} || exit 1
./configure && make && make install

# install php 
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/php-${PHP}.tar.gz https://www.php.net/distributions/php-${PHP}.tar.gz
tar xzf php-${PHP}.tar.gz

cd php-${PHP} || exit 1
./configure --enable-ctype --enable-exif --enable-ftp --with-curl --with-zlib --with-mysql-sock=/tmp/mysql.sock --with-pdo-mysql=shared,mysqlnd --with-mysqli=shared,mysqlnd --enable-mbstring --enable-inline-optimization --disable-debug --enable-sockets --disable-short-tags --enable-phar --enable-fpm --with-fpm-user=$WWWUSER --with-fpm-group=$WWWUSER --with-gd --with-openssl --enable-bcmath --enable-shmop --enable-mbregex --with-iconv --with-mhash --enable-pcntl --enable-zip --enable-soap --enable-session --without-gdbm --with-config-file-path=/etc --with-jpeg-dir=/usr/local --with-freetype-dir=/usr/local --with-webp-dir=/usr/local
make && make install

# php config
cp ./sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm -r
cp ./php.ini-development $PHP_INI -r
cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf -r
cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf
/bin/sed -i -e 's/^include=NONE.*$/include=etc\/php-fpm.d\/\*.conf/' /usr/local/etc/php-fpm.conf
chmod +x /etc/init.d/php-fpm
chkconfig --add php-fpm
chkconfig php-fpm on

/usr/local/bin/pecl install yaf-${PHP_YAF}
/usr/local/bin/pecl install msgpack-${PHP_MSGPACK}
/usr/local/bin/pecl install mongodb-${PHP_MONGODB}
printf "yes\n" | /usr/local/bin/pecl install yar-${PHP_YAR}
printf "no\n" | /usr/local/bin/pecl install redis-${PHP_REDIS}
printf "no\n" | /usr/local/bin/pecl install apcu-${PHP_APCU}
{
  echo 'extension=msgpack.so'
  echo 'extension=redis.so'
  echo 'extension=mysqli.so'
  echo 'extension=pdo_mysql.so'
  echo 'extension=yaf.so'
  echo 'extension=mongodb.so'
  echo 'extension=yar.so'
  echo 'extension=apcu.so'
} >> ${PHP_INI}

/bin/sed -i -e 's/^[;]\{0,1\}date.timezone =.*$/date.timezone = PRC/' $PHP_INI
# install compoer 
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/composer.phar https://github.com/composer/composer/releases/download/${COMPOSER}/composer.phar
/bin/cp -rf /usr/local/src/composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# install cachetool 
cd /usr/local/src || exit 1
curl -L -o /usr/local/bin/cachetool https://github.com/gordalina/cachetool/raw/gh-pages/downloads/cachetool-${CACHETOOL}.phar
chmod +x /usr/local/bin/cachetool

# install tengine
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/pcre-${PCRE}.tar.gz https://ftp.pcre.org/pub/pcre/pcre-${PCRE}.tar.gz
tar xzf pcre-${PCRE}.tar.gz
curl -L -o /usr/local/src/tengine-${NGINX}.tar.gz http://tengine.taobao.org/download/tengine-${NGINX}.tar.gz
tar xzf tengine-${NGINX}.tar.gz
cd tengine-${NGINX} || exit 1
./configure --with-select_module --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-pcre=/usr/local/src/pcre-${PCRE} --with-http_geoip_module
make && make install
# 
## install redis
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/redis-${REDIS}.tar.gz http://download.redis.io/releases/redis-${REDIS}.tar.gz
tar xzf redis-${REDIS}.tar.gz
cd redis-${REDIS} || exit 1
make && make install
mkdir -p /etc/redis
cp -f ./*.conf /etc/redis
sed -i -e "s/redis_\${REDIS_PORT}/redis-server/" ./utils/install_server.sh
sed -i -e "s/redis_\$REDIS_PORT/redis-server/" ./utils/install_server.sh
cat << CMD | ./utils/install_server.sh
6379
/etc/redis/redis.conf



CMD

## install mysql

groupadd $MYSQLUSER
useradd -r -g $MYSQLUSER -s /bin/false $MYSQLUSER
cd /usr/local/src || exit 1
rm /usr/local/mysql/* -rf
rm /var/lib/mysql/ib* -rf
curl -L -o /usr/local/src/mysql-${MYSQL}.tar.gz https://dev.mysql.com/get/Downloads/MySQL-${MAIN_MYSQL}/mysql-${MYSQL}.tar.gz
tar xzf mysql-${MYSQL}.tar.gz
cd mysql-${MYSQL} || exit 1
cmake .
make && make install

## install mysql init
cd /usr/local/mysql || exit 1
./scripts/mysql_install_db --user=$MYSQLUSER
cp support-files/mysql.server /etc/init.d/mysql
chkconfig --add mysql
chkconfig mysql on

## nginx config
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
chkconfig nginx on

mkdir -p /usr/local/nginx/conf/servers
echo "Creating servers nginx conf"
(
cat <<'EOF'
user www;
worker_processes  2;

error_log  logs/error.log;
#pid        logs/nginx.pid;

events {
    worker_connections  10240;
    use epoll;
}
http {
    include       mime.types;
    server_tag "SOEASY4.0";
    server_info off;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for" "$request_time"';

    access_log  logs/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  65;
    fastcgi_connect_timeout 120s;
    fastcgi_send_timeout 120s;
    fastcgi_read_timeout 120s;
    client_header_buffer_size 4k;
    client_body_buffer_size 128k;
    client_max_body_size 20M;
    gzip  on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_disable "MSIE [1-6]\.";
    gzip_types text/plain application/javascript application/x-javascript text/css application/xml image/jpeg;
    include servers/default.conf;
}
EOF
) | tee /usr/local/nginx/conf/nginx.conf

echo "Creating /usr/local/nginx conf"
(
cat <<'EOF'
server {
     listen       80 default;
     server_name  localhost;
     location / {
         root   html;
         index  index.html index.htm;
     }
     error_page   500 502 503 504  /50x.html;
     location = /50x.html {
         root   html;
     }
 }
EOF
) | tee /usr/local/nginx/conf/servers/default.conf

reboot
