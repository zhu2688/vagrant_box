#!/bin/bash
#Provided by @soeasy

PHP="7.4.7"
NGINX="2.3.2"
PCRE="8.43"
REDIS="5.0.7"
MYSQL="8.0.19"
LIB_FREETYPE='2.9.1'
LIB_ZIP="1.6.0"
LIB_GD="2.2.5"
LIB_ONIGURUMA="6.9.3"
CMAKE='3.12.4'
COMPOSER="1.9.2"
PHP_REDIS="5.1.1"
PHP_YAF="3.0.9"
PHP_YAR="2.0.5"
PHP_MSGPACK="2.0.3"
PHP_MONGODB="1.6.1"
PHP_APCU="5.1.18"
CACHETOOL="4.1.1"
COUNTRY="CN"
COUNTRY_FILE="/tmp/country"
WWWUSER="www"
DB_USER="mysql"
DB_DATA_PATH="/data/mysql"
PHP_INI="/etc/php.ini"
REDIS_INI="/etc/redis/redis.conf"

RELEASE=`cat /etc/redhat-release`
groupadd $WWWUSER
useradd -r -g $WWWUSER -s /sbin/nologin -g $WWWUSER -M $WWWUSER
# yum update
curl -o $COUNTRY_FILE ifconfig.co/country-iso
checkCN=$(< $COUNTRY_FILE grep $COUNTRY)

if [[ -n $checkCN ]]; then
  if [[ -f /usr/local/qcloud ]]; then
      curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
      curl -o /etc/yum.repos.d/epel.repo http://mirrors.cloud.tencent.com/repo/epel-7.repo
  elif [ -f /usr/sbin/aliyun-service ]; then
      curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
      curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
  else
      curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
  fi
fi

rm -rf /var/cache/yum
yum makecache
/bin/sed -i -e '/^export.*mysql\/bin.*$/d' /etc/profile
echo "export PATH=\"\$PATH:/usr/local/mysql/bin:/usr/local/bin:\$PATH\";" >> /etc/profile
source /etc/profile

yum -y install epel-release telnet git wget centos-release-scl scl-utils ncurses-devel bison autoconf automake libtool openssl openssl-devel curl-devel geoip-devel psmisc bzip2

killall php-fpm
killall mysql
killall nginx
# install lib devel
yum -y install devtoolset-8 libxml2 libxml2-devel libjpeg-devel freetype-devel libpng-devel sqlite-devel libwebp-devel

source /opt/rh/devtoolset-8/enable

# install freetype
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/freetype-${LIB_FREETYPE}.tar.gz https://download.savannah.gnu.org/releases/freetype/freetype-${LIB_FREETYPE}.tar.gz
tar xzf freetype-${LIB_FREETYPE}.tar.gz
cd freetype-${LIB_FREETYPE} || exit 1
./configure && make && make install

# install cmake
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/cmake-${CMAKE}.tar.gz https://cmake.org/files/v3.12/cmake-${CMAKE}.tar.gz
tar xzf cmake-${CMAKE}.tar.gz
cd cmake-${CMAKE} || exit 1
# export CC=/usr/local/bin/gcc
# export CXX=/usr/local/bin/g++
./configure && make && make install && make clean

# install libzip
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/libzip-${LIB_ZIP}.tar.gz https://nih.at/libzip/libzip-${LIB_ZIP}.tar.gz
tar xzf libzip-${LIB_ZIP}.tar.gz
cd libzip-${LIB_ZIP} || exit 1
mkdir -p build
cd build && cmake .. && make && make install
/bin/cp /usr/local/lib64/pkgconfig/libzip.pc /usr/lib64/pkgconfig/libzip.pc -rf

# install libgd
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/libgd-${LIB_GD}.tar.gz https://github.com/libgd/libgd/releases/download/gd-${LIB_GD}/libgd-${LIB_GD}.tar.gz
tar xzf libgd-${LIB_GD}.tar.gz
cd libgd-${LIB_GD} || exit 1
./configure && make && make install

# install oniguruma
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/oniguruma-${LIB_ONIGURUMA}.tar.gz https://github.com/kkos/oniguruma/releases/download/v${LIB_ONIGURUMA}/onig-${LIB_ONIGURUMA}.tar.gz
tar xzf oniguruma-${LIB_ONIGURUMA}.tar.gz
cd onig-${LIB_ONIGURUMA} || exit 1
./configure && make && make install
export ONIG_CFLAGS="-I/usr/local/include" ONIG_LIBS="-L/usr/local/lib -lonig"

# install php
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/php-${PHP}.tar.gz https://www.php.net/distributions/php-${PHP}.tar.gz
tar xzf php-${PHP}.tar.gz
cd php-${PHP} || exit 1
./configure --enable-ctype --enable-exif --enable-ftp --with-curl --with-mysql-sock=/tmp/mysql.sock --with-pdo-mysql=shared,mysqlnd --with-mysqli=shared,mysqlnd --enable-mbstring --enable-inline-optimization --disable-debug --enable-sockets --disable-short-tags --enable-phar --enable-fpm  --with-pear --with-fpm-user=$WWWUSER --with-fpm-group=$WWWUSER --enable-gd --with-openssl --enable-bcmath --enable-shmop --enable-mbregex --with-iconv --with-mhash --enable-pcntl --enable-soap --enable-session --without-gdbm --without-sqlite3 --without-pdo-sqlite --with-config-file-path=/etc --with-zip --with-zip --with-zlib --with-freetype
make && make install && make clean

# php config
/bin/mkdir -p /usr/local/etc/php-fpm.d/
/bin/cp ./sapi/fpm/php-fpm.service /usr/lib/systemd/system/php-fpm.service -r
/bin/sed -i -e 's/^PIDFile=.*$/PIDFile=\/var\/run\/php-fpm.pid/' /usr/lib/systemd/system/php-fpm.service

/bin/cp ./php.ini-development $PHP_INI -r
/bin/cp ./sapi/fpm/php-fpm.conf /usr/local/etc/php-fpm.conf -r
/bin/cp ./sapi/fpm/www.conf /usr/local/etc/php-fpm.d/www.conf -r
/bin/sed -i -e 's/^include=NONE.*$/include=etc\/php-fpm.d\/\*.conf/' /usr/local/etc/php-fpm.conf
/bin/sed -i -e 's|;pid = run/php-fpm.pid|pid = /var/run/php-fpm.pid|g' /usr/local/etc/php-fpm.conf
/bin/sed -i -e 's|;error_log = log/php-fpm.log|error_log = /var/log/php-fpm.log|g' /usr/local/etc/php-fpm.conf

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
  echo 'extension=mongodb.so'
  echo 'extension=yar.so'
  echo 'extension=apcu.so'
} >> ${PHP_INI}

echo '[yaf]
extension=yaf.so
yaf.environ=dev
' >> $PHP_INI

/bin/sed -i -e 's/^[;]\{0,1\}date.timezone =.*$/date.timezone = PRC/' $PHP_INI

# install compoer
cd /usr/local/src || exit 1
curl -L -o /usr/local/bin/composer https://github.com/composer/composer/releases/download/${COMPOSER}/composer.phar
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
./configure --with-select_module --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-pcre=/usr/local/src/pcre-${PCRE} --with-ipv6 --with-http_geoip_module
make && make install

## nginx config
mkdir -p /usr/local/nginx/conf/servers
echo "Creating servers nginx conf"
(
cat <<'EOF'
user www;
worker_processes  2;

error_log  logs/error.log;
pid        /var/run/nginx.pid;

events {
    worker_connections  10240;
    use epoll;
}
http {
    include       mime.types;
    server_tag "SOEASY7.0";
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
    # server_name  _;
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

echo "Create /usr/local/nginx/conf/servers/web_app.conf"
(
cat <<'EOF'
server {
    listen       80;
    server_name  app.test.com;
    charset utf-8;
    access_log  logs/app-access.log  main;
    error_log   logs/app-error.log;
    root /data/www/web_app/public;
    index index.htm index.html index.php;
    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }
    location = /robots.txt {
        access_log off;
        log_not_found off;
    }
    location = /sitemap.xml {
        access_log off;
        log_not_found off;
    }
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
    if ($request_method ~ ^(HEAD)$ ) {
      return 200;
    }
    location / {
        try_files $uri $uri/ /index.php?/$request_uri;
    }
    location ~ \.php$ {
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
}
EOF
) | tee /usr/local/nginx/conf/servers/web_app.conf

echo "Creating /usr/lib/systemd/system/nginx.service"
(
cat <<'EOF'
[Unit]
Description=The Nginx Server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecStartPost=/bin/sleep 0.1
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target

EOF
) | tee /usr/lib/systemd/system/nginx.service

## install redis
cd /usr/local/src || exit 1
curl -L -o /usr/local/src/redis-${REDIS}.tar.gz http://download.redis.io/releases/redis-${REDIS}.tar.gz
tar xzf redis-${REDIS}.tar.gz
cd redis-${REDIS} || exit 1
make && make install
mkdir -p /etc/redis
cp -f *.conf /etc/redis

/bin/sed -i -e 's/^pidfile.*$/pidfile \/var\/run\/redis.pid/' $REDIS_INI
/bin/sed -i -e 's/^daemonize.*$/daemonize yes/' $REDIS_INI

echo "Creating /usr/lib/systemd/system/redis.service"
(
cat <<'EOF'
[Unit]
Description=The Redis Server
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/var/run/redis.pid
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStartPost=/bin/sleep 0.1
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF
) | tee /usr/lib/systemd/system/redis.service

chmod +x /usr/lib/systemd/system/php-fpm.service
chmod +x /usr/lib/systemd/system/redis.service
chmod +x /usr/lib/systemd/system/nginx.service

systemctl disable firewalld.service
systemctl stop firewalld.service

systemctl daemon-reload

systemctl enable php-fpm.service
systemctl enable redis.service
systemctl enable nginx.service

systemctl restart php-fpm
systemctl restart redis
systemctl restart nginx

## install MySQL
# 本地虚拟机不安装mysql 占用空间太大
if [ ! -d /vagrant ]; then
curl -L -o /usr/local/src/mysql80-community-release-el7.rpm http://repo.mysql.com/mysql80-community-release-el7.rpm
cd /usr/local/src || exit 1
rpm -ivh mysql80-community-release-el7.rpm
yum -y install mysql-server
# mysql 随机生成的密码 在 /var/log/mysqld.log 中可以看到
# cat /var/log/mysqld.log | grep "password"
systemctl enable mysqld.service
fi
