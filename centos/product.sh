#!/bin/bash
#Provided by @soeasy

EXPOSE_PHP="Off"
DATE_TIMEZONE="PRC"
MAX_EXECUTION_TIME="90"
UPLOAD_MAX_FILESIZE="20M"
POST_MAX_SIZE="20M"
MEMORY_LIMIT="192M"
DISABLE_FUNCTIONS="show_source,system,shell_exec,passthru,exec,proc_open,proc_get_status,phpinfo"
REDIS_INI="/etc/redis/redis.conf"

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
  
  /bin/sed -i -e "s/^[;]\{0,1\}expose_php =.*$/expose_php = ${EXPOSE_PHP}/" "$PATH_PHP_INI"
  /bin/sed -i -e "s/^[;]\{0,1\}date.timezone =.*$/date.timezone = ${DATE_TIMEZONE}/" "$PATH_PHP_INI"
  /bin/sed -i -e "s/^max_execution_time =.*$/max_execution_time = ${MAX_EXECUTION_TIME}/" "$PATH_PHP_INI"
  /bin/sed -i -e "s/^upload_max_filesize =.*$/upload_max_filesize = ${UPLOAD_MAX_FILESIZE}/" "$PATH_PHP_INI"
  /bin/sed -i -e "s/^post_max_size =.*$/post_max_size = ${POST_MAX_SIZE}/" "$PATH_PHP_INI"
  /bin/sed -i -e "s/^memory_limit =.*$/memory_limit = ${MEMORY_LIMIT}/" "$PATH_PHP_INI"
  # disable_functions
  /bin/sed -i -e "s/^[;]\{0,1\}disable_functions.*$/disable_functions = ${DISABLE_FUNCTIONS}/" "$PATH_PHP_INI"
  # opcache 
  /bin/sed -i -e "s/^[;]\{0,1\}opcache.enable.*$/opcache.enable = 1/" "$PATH_PHP_INI"
  /bin/sed -i -e '/^zend_extension.*opcache.*$/d' "$PATH_PHP_INI"
  echo "zend_extension=opcache.so" >> "$PATH_PHP_INI"
else
  echo "$PATH_PHP_INI is not exist!"
fi
