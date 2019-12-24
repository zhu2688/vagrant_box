#!/bin/bash
#Provided by @soeasy

log(){
    Time=$(date +%F" "%T)
    echo "$Time [$1]: $2" >>/opt/product_shell.log 2>&1
}
MEM_TOTAL=`free -m | grep Mem | awk '{print  $2}'`

PHP_EXPOSE="Off"
PHP_DATE_TIMEZONE="PRC"
PHP_MAX_EXECUTION_TIME="90"
PHP_UPLOAD_MAX_FILESIZE="20M"
PHP_POST_MAX_SIZE="20M"
PHP_MEMORY_LIMIT="192M"
PHP_DISABLE_FUNCTIONS="show_source,system,shell_exec,passthru,exec,proc_get_status,phpinfo"
PHP_YAF_ENVIRON=`/usr/bin/env php --ri yaf | grep yaf.environ | awk '{print $5}'`

REDIS_CONF="/etc/redis/redis.conf"
REDIS_BIND_ADDRESS="127.0.0.1"
REDIS_DATA_PATH="/data/redis"
REDIS_MAX_MEMORY="150Mb"
REDIS_APPEND_ONLY="yes"
REDIS_DAEMONIZE="no"

MYSQL_CONF="/etc/my.cnf"
MYSQL_BIND_ADDRESS="127.0.0.1"

NGINX_CONF="/usr/local/nginx/conf/nginx.conf"

SYSCTL_CONF="/etc/sysctl.conf"
LIMITS_CONF="/etc/security/limits.conf"

DATA_ACMESH_PATH="/data/acme.sh"
DATA_SHELL_PATH="/data/shell"
DATA_WWW_PATH="/data/www"
DATA_NGINX_BADBOT_PATH="/data/nginx/badbot"

CRONTAB_PATH="/var/spool/cron/root"

/bin/mkdir -p ${DATA_NGINX_PATH} ${DATA_SHELL_PATH} ${DATA_WWW_PATH}

yum -y install crontabs supervisor ntpdate

## 1 php config
if ! command -v php
then
  echo "php command is not exist!"  && exit 1
fi
PATH_PHP_INI=$(php -i | grep "Loaded Configuration File" | sed -e 's/Loaded Configuration File => //g')
if [ ! -f "$PATH_PHP_INI" ]; then
  echo "$PATH_PHP_INI is not exist!" && exit 1
fi

/bin/sed -i -e 's/^error_reporting =.*$/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/' "$PATH_PHP_INI"
/bin/sed -i -e 's/^display_startup_errors = On$/display_startup_errors = Off/' "$PATH_PHP_INI"
/bin/sed -i -e 's/^[;]\{0,1\}display_errors = On$/display_errors = Off/' "$PATH_PHP_INI"
/bin/sed -i -e 's/^[;]\{0,1\}log_errors = Off$/display_errors = On/' "$PATH_PHP_INI"

/bin/sed -i -e "s/^[;]\{0,1\}expose_php =.*$/expose_php = ${PHP_EXPOSE}/" "$PATH_PHP_INI"
/bin/sed -i -e "s/^[;]\{0,1\}date.timezone =.*$/date.timezone = ${PHP_DATE_TIMEZONE}/" "$PATH_PHP_INI"
/bin/sed -i -e "s/^max_execution_time =.*$/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/" "$PATH_PHP_INI"
/bin/sed -i -e "s/^upload_max_filesize =.*$/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" "$PATH_PHP_INI"
/bin/sed -i -e "s/^post_max_size =.*$/post_max_size = ${PHP_POST_MAX_SIZE}/" "$PATH_PHP_INI"
/bin/sed -i -e "s/^memory_limit =.*$/memory_limit = ${PHP_MEMORY_LIMIT}/" "$PATH_PHP_INI"
# disable_functions
/bin/sed -i -e "s/^[;]\{0,1\}disable_functions.*$/disable_functions = ${PHP_DISABLE_FUNCTIONS}/" "$PATH_PHP_INI"
# opcache
/bin/sed -i -e "s/^[;]\{0,1\}opcache.enable\s\?=.*$/opcache.enable=1/" "$PATH_PHP_INI"
/bin/sed -i -e '/^zend_extension.*opcache.*$/d' "$PATH_PHP_INI"
echo "zend_extension=opcache.so" >> "$PATH_PHP_INI"

if [ ! -z $PHP_YAF_ENVIRON ]; then
  /bin/sed -i -e '/^yaf\.environ=.*$/d' $PATH_PHP_INI
fi

## 2 redis config
if [ ! -f "$REDIS_CONF" ]; then
  echo "$REDIS_CONF is not exist!" && exit 1
fi

/bin/mkdir -p ${REDIS_DATA_PATH}/{logs,data}
/bin/sed -i "s/^bind.*/bind ${REDIS_BIND_ADDRESS}/" "$REDIS_CONF"
# /bin/sed -i "s/^protected-mode/bind ${REDIS_BIND_ADDRESS}/" "$REDIS_CONF"
# ?protected-mode
# sed -i 's/^port 6379/port '${REDIS_PORT}'/' "$REDIS_CONF"
/bin/sed -i "s/# maxmemory <bytes>/maxmemory ${REDIS_MAX_MEMORY}/" "$REDIS_CONF"
/bin/sed -i "s/# maxmemory-policy noeviction/maxmemory-policy volatile-lru/" "$REDIS_CONF"
/bin/sed -i "s/appendonly no/appendonly ${REDIS_APPEND_ONLY}/" "$REDIS_CONF"
/bin/sed -i "s/^daemonize no/daemonize ${REDIS_DAEMONIZE}/" $REDIS_CONF
/bin/sed -i "s!^dir.*!dir "${REDIS_DATA_PATH}"/data!" "$REDIS_CONF"

## 3 mysql config
if [ ! -f "$MYSQL_CONF" ]; then
  echo "$MYSQL_CONF is not exist!" && exit 1
fi

if [[ ${MEM_TOTAL} -gt 1024 && ${MEM_TOTAL} -lt 2048 ]]; then
  InnodbBufferPoolSize=256M
elif [[ ${MEM_TOTAL} -ge 2048 && ${MEM_TOTAL} -lt 4096 ]]; then
  InnodbBufferPoolSize=512M
else
  InnodbBufferPoolSize=1G
fi

/bin/sed -i -e '/^innodb_data_file_path.*$/d' $MYSQL_CONF
/bin/sed -i -e '/^innodb_buffer_pool_size.*$/d' $MYSQL_CONF
/bin/sed -i -e '/^max_connections.*$/d' $MYSQL_CONF
/bin/sed -i -e '/^connect-timeout.*$/d' $MYSQL_CONF
/bin/sed -i -e '/^innodb_lock_wait_timeout.*$/d' $MYSQL_CONF

echo 'innodb_data_file_path=ibdata1:50M:autoextend' >> $MYSQL_CONF
echo "innodb_buffer_pool_size=${InnodbBufferPoolSize}" >> $MYSQL_CONF
echo 'max_connections=500' >> $MYSQL_CONF
echo 'connect-timeout=10' >> $MYSQL_CONF
echo 'innodb_lock_wait_timeout=50' >> $MYSQL_CONF

#todo

/usr/local/mysql/bin/mysql -uroot <<-EOF
DELETE FROM mysql.user where user='' or (Host != '127.0.0.1' and Host !='localhost');
flush privileges;
EOF

## 4 nginx config
if [ ! -f "$NGINX_CONF" ]; then
  echo "$NGINX_CONF is not exist!" && exit 1
fi

if [ ! -d ${DATA_NGINX_BADBOT_PATH} ]; then
    /usr/bin/git clone https://github.com/zhu2688/nginx-base-badbot-blocker ${DATA_NGINX_BADBOT_PATH}
fi
cd ${DATA_NGINX_BADBOT_PATH} || exit 1
git pull

## 5 ssl
if [ ! -d ${DATA_ACMESH_PATH} ]; then
    /usr/bin/git clone https://github.com/Neilpang/acme.sh.git ${DATA_ACMESH_PATH}
fi
cd ${DATA_ACMESH_PATH} || exit 1
## 6 /etc/sysctl.conf
sysctl -p

## 7 sys service
if [ -a ${CRONTAB_PATH} ]; then
	sed -i "/^.*ntpdate.*$/d" ${CRONTAB_PATH}
    sed -i "/^.*db_backup.*$/d" ${CRONTAB_PATH}
fi
echo "0 2 * * * (/usr/sbin/ntpdate ntp1.aliyun.com && /sbin/hwclock -w) > /dev/null 2>&1" >> ${CRONTAB_PATH}
echo "10 0 * * * /data/www/admin/application/bin/db_backup.sh >> /data/www/admin/application/logs/crond.log 2>&1 &" >> ${CRONTAB_PATH}

/sbin/chkconfig crond on
/sbin/chkconfig supervisord on
cat /etc/redhat-release |grep 7\\..*|grep -i centos > /dev/null
if [ $? -eq 0 ];then
    systemctl stop php-fpm.service
    systemctl stop redis.service
    systemctl stop nginx.service

    systemctl start php-fpm.service
    systemctl start redis.service
    systemctl start nginx.service
    systemctl restart crond
else
    service php-fpm restart
    service mysql restart
    service nginx restart
    service redis-server restart
    service crond restart
fi
