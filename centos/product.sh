#!/bin/bash
#Provided by @soeasy

PHP_EXPOSE="Off"
PHP_DATE_TIMEZONE="PRC"
PHP_MAX_EXECUTION_TIME="90"
PHP_UPLOAD_MAX_FILESIZE="20M"
PHP_POST_MAX_SIZE="20M"
PHP_MEMORY_LIMIT="192M"
PHP_DISABLE_FUNCTIONS="show_source,system,shell_exec,passthru,exec,proc_open,proc_get_status,phpinfo"
PHP_YAF_ENVIRON=`/usr/bin/env php --ri yaf | grep yaf.environ | awk '{print $5}'`

REDIS_INI="/etc/redis/redis.conf"
REDIS_DATA_PATH="/opt/redis/data"
REDIS_MAX_MEMORY="150mb"
REDIS_APPEND_ONLY="yes"
REDIS_DAEMONIZE="no"

## 1 php config
if ! command -v php
then
  echo "php command is not exist!"  && exit 1
fi
PATH_PHP_INI=$(php -i | grep "Loaded Configuration File" | sed -e 's/Loaded Configuration File => //g')
if [ -f "$PATH_PHP_INI" ]; then
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
else
  echo "$PATH_PHP_INI is not exist!"
fi
  
if [ ! -z $PHP_YAF_ENVIRON ]; then
  /bin/sed -i -e '/^yaf\.environ=.*$/d' $PATH_PHP_INI
fi

## 2 redis config
sed -i "s/^bind.*/bind 127.0.0.1/" $REDIS_INI
sed -i "s/# maxmemory <bytes>/maxmemory ${REDIS_MAX_MEMORY}/" $REDIS_INI
sed -i 's/# maxmemory-policy noeviction/maxmemory-policy volatile-lru/' $REDIS_INI
sed -i "s/appendonly no/appendonly ${REDIS_APPEND_ONLY}/" $REDIS_INI
sed -i "s/^daemonize no/daemonize ${REDIS_DAEMONIZE}/" $REDIS_INI

## 3 mysql config