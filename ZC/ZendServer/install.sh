#!/bin/bash

MYUID=`id -u 2> /dev/null`

if [ ! -z "$MYUID" ]; then
    if [ $MYUID -ne 0 ]; then
        echo "You need root privileges to run this script!";
        exit -1
    fi
else
    echo "Could not detect UID";
    exit -1
fi
PRODUCT_NAME="Zend Server"
PRODUCT_VERSION=5.5.0
TARGET_DIR="zend"
APACHE_VER=2.2.15
WEB_USER=daemon
WEB_UID=`id -u daemon`
WEB_GID=`id -g daemon`
RC_FILE=/etc/zce.rc
ZEND_USER=zend
if [ "$1" = '-g' ];then
    PREFIX=/usr/local
else
    echo "Welcome to $PRODUCT_NAME installation script!"
    echo "Please specify an installation path [/usr/local]:"
    read -e PREFIX
    if [ -z $PREFIX ];then
        PREFIX="/usr/local"
    fi
fi
if [ ! -d ${PREFIX} ];then
    mkdir -p ${PREFIX}
fi
ZCE_PREFIX=`readlink -f ${PREFIX}`/${TARGET_DIR}
if [ -d ${ZCE_PREFIX}/apache2/htdocs ];then mv -f ${ZCE_PREFIX}/apache2/htdocs ${ZCE_PREFIX}/apache2/htdocs.bak-`date +%m%d%y`;fi
if [ -d ${ZCE_PREFIX}/etc ];then mv -f ${ZCE_PREFIX}/etc ${ZCE_PREFIX}/etc.bak-`date +%m%d%y`;fi
echo "Extracting files to ${ZCE_PREFIX}..."
`dirname $0`/7z x -o$PREFIX -y `dirname $0`/$TARGET_DIR.7z 1>/dev/null
if [ $? -ne 0 ];then 
    echo "Failed to extract files.. "
    exit 1
fi
. ${ZCE_PREFIX}/bin/shell_functions.rc
groupadd $ZEND_USER
useradd -d ${ZCE_PREFIX}/gui/lighttpd -s /sbin/nologin -g $ZEND_USER $ZEND_USER 2>/dev/null
if ! id -g $ZEND_USER > /dev/null 2>&1 ;then
	echo "Could not create the zend group. This is mandatory for $PRODUCT_NAME to function properly. Aborting installation.."
	exit 1
fi
if ! id -u $ZEND_USER > /dev/null 2>&1 ;then
	echo "Could not create the zend user. This is mandatory for $PRODUCT_NAME to function properly. Aborting installation.."
	exit 1
fi
chown -R $WEB_USER:$ZEND_USER $ZCE_PREFIX/tmp $ZCE_PREFIX/var
chmod g+swx,o+x $ZCE_PREFIX/tmp $ZCE_PREFIX/var/log
touch $ZCE_PREFIX/var/log/php.log 
chown $WEB_USER $ZCE_PREFIX/var/log/php.log
mkdir $ZCE_PREFIX/tmp/datacache-ce
chown -R $WEB_USER $ZCE_PREFIX/tmp/datacache-ce
chgrp -R $ZEND_USER $ZCE_PREFIX/etc
chmod 664 $ZCE_PREFIX/etc/* $ZCE_PREFIX/etc/conf.d/*
chmod g+xsw,o+x $ZCE_PREFIX/etc $ZCE_PREFIX/etc/conf.d
chgrp -R $ZEND_USER $ZCE_PREFIX/gui/application/data
chmod -R g+sw $ZCE_PREFIX/gui/application/data
chown $ZEND_USER:$ZEND_USER $ZCE_PREFIX/gui/lighttpd/logs $ZCE_PREFIX/gui/lighttpd/tmp
INSTALLATION_UID=`date +%m%d%y%H%M%S`
echo "ZCE_PREFIX=${ZCE_PREFIX}" >$RC_FILE 
# for PEAR and PECL:
echo "PHP_PEAR_PHP_BIN=${ZCE_PREFIX}/bin/php" >> $RC_FILE
echo "PHP_PEAR_INSTALL_DIR=${ZCE_PREFIX}/share/pear" >> $RC_FILE
echo "if [ -z \$LD_LIBRARY_PATH ];then" >>$RC_FILE
echo "   LD_LIBRARY_PATH=/lib:/usr/lib:$ZCE_PREFIX/lib:$ZCE_PREFIX/apache2/lib"  >>$RC_FILE
echo "else"  >>$RC_FILE
echo "    LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$ZCE_PREFIX/lib:$ZCE_PREFIX/apache2/lib"  >>$RC_FILE
echo "fi"  >>$RC_FILE
echo "export LD_LIBRARY_PATH"  >>$RC_FILE
echo "APACHE_VER=${APACHE_VER}"  >>$RC_FILE
echo "WEB_USER=${WEB_USER}"  >>$RC_FILE
echo "APACHE_PID_FILE=$ZCE_PREFIX/apache2/logs/httpd.pid"  >>$RC_FILE
echo "APACHE_HTDOCS=$ZCE_PREFIX/apache2/htdocs"  >>$RC_FILE
echo "APACHE_PORT=10088"  >>$RC_FILE
echo "PRODUCT_NAME=\"${PRODUCT_NAME}\""  >>$RC_FILE
echo "PRODUCT_VERSION=${PRODUCT_VERSION}"  >>$RC_FILE
echo "export INSTALLATION_UID=${INSTALLATION_UID}"  >>$RC_FILE
echo "DIST=ce"  >>$RC_FILE

find $ZCE_PREFIX/gui/html -exec touch {} \;

sed -i s@INSTALLATION_PLACEHOLDER_VERSION@$PRODUCT_VERSION@g  ${ZCE_PREFIX}/gui/application/data/zend-server.ini
sed -e s@INSTALLATION_PLACEHOLDER_USER_SERVER_URL@http://localhost:10083/ZendServer@g -i ${ZCE_PREFIX}/gui/application/data/zend-server.ini
sed -e s@INSTALLATION_PLACEHOLDER_REWRITE_ENABLED@On@g -i ${ZCE_PREFIX}/gui/application/data/zend-server.ini
sed -i s@ZCE_PREFIX@${ZCE_PREFIX}@g ${ZCE_PREFIX}/etc/*.ini
sed -i s@ZCE_PREFIX@${ZCE_PREFIX}@g ${ZCE_PREFIX}/etc/conf.d/extension_manager.ini
sed -i s@ZEND_PREFIX@${ZCE_PREFIX}@g ${ZCE_PREFIX}/etc/conf.d/ZendGlobalDirectives.ini
sed -i s@HTTPD_UID@$WEB_UID@g ${ZCE_PREFIX}/etc/conf.d/ZendGlobalDirectives.ini
sed -i s@HTTPD_GID@$WEB_GID@g ${ZCE_PREFIX}/etc/conf.d/ZendGlobalDirectives.ini
sed -i s@/usr/local/zend@${ZCE_PREFIX}@g ${ZCE_PREFIX}/apache2/conf/*.conf
sed -i s@/usr/local/zend@${ZCE_PREFIX}@g ${ZCE_PREFIX}/apache2/conf/extra/*.conf
# fix PECL and PEAR according to actual prefix:
sed -i s@/usr/local/zend@${ZCE_PREFIX}@g ${ZCE_PREFIX}/share/pear/pearcmd.php ${ZCE_PREFIX}/share/pear/pearcmd.php 
sed -i s@ZCE_PREFIX@${ZCE_PREFIX}@g ${ZCE_PREFIX}/apache2/conf.d/*.conf
sed -i s@ZCE_PREFIX@${ZCE_PREFIX}@g ${ZCE_PREFIX}/gui/lighttpd/etc/lighttpd.conf
sed -i s@ZCE_PREFIX@${ZCE_PREFIX}@g ${ZCE_PREFIX}/gui/lighttpd/etc/php-fcgi.ini
sed -i s@HTTPD_UID@$WEB_UID@g ${ZCE_PREFIX}/gui/lighttpd/etc/php-fcgi.ini
sed "s@^prefix='.*'@prefix=${ZCE_PREFIX}@g" -i ${ZCE_PREFIX}/bin/phpize
sed -i 's@#Include conf/extra/httpd-autoindex.conf@Include conf/extra/httpd-autoindex.conf@g' ${ZCE_PREFIX}/apache2/conf/httpd.conf 
sed -i s@/usr/local/zend@${ZCE_PREFIX}@g  ${ZCE_PREFIX}/apache2/conf.d/*.conf
sed -i s@/usr/local/zend@${ZCE_PREFIX}@g ${ZCE_PREFIX}/apache2/bin/apachectl
sed -i s@ZCE_PREFIX@${ZCE_PREFIX}@g ${ZCE_PREFIX}/share/bugreport/*
# place path for each ext:
for ext in datacache optimizerplus debugger utils ;do
    sed -i "s@zend_extension_manager.dir.$ext=@zend_extension_manager.dir.$ext=${ZCE_PREFIX}/lib/$ext@g" ${ZCE_PREFIX}/etc/conf.d/$ext.ini
done
# these should be commented by default:
for ext in loader jbridge ;do
    INI_FILE=${ZCE_PREFIX}/etc/conf.d/$ext.ini
    if [ -f $INI_FILE ];then
        sed -i "s@zend_extension_manager.dir.$ext=@;zend_extension_manager.dir.$ext=${ZCE_PREFIX}/lib/$ext@g" $INI_FILE
    fi
done
sed -i "s@^zend_datacache.disk.save_path=datacache\$@zend_datacache.disk.save_path=${ZCE_PREFIX}/tmp/datacache-ce@g" ${ZCE_PREFIX}/etc/conf.d/datacache.ini
find ${ZCE_PREFIX}/etc/conf.d/ -name "*.ini" -exec sed -i 's/ini_filename=.*\|subpath=.*//g' {} \;
sed -i "s@\s*extension_dir\s*=.*@extension_dir='${ZCE_PREFIX}/lib/php_extensions'@" ${ZCE_PREFIX}/bin/php-config
sed -i "s@ZCE_PREFIX@${ZCE_PREFIX}@g" ${ZCE_PREFIX}/gui/application/data/logfiles.xml

cp ${ZCE_PREFIX}/etc/conf.d/optimizerplus.ini  ${ZCE_PREFIX}/gui/lighttpd/etc/conf.d/optimizerplus.ini
cp ${ZCE_PREFIX}/etc/conf.d/extension_manager.ini  ${ZCE_PREFIX}/gui/lighttpd/etc/conf.d/extension_manager.ini
ln -sf ${ZCE_PREFIX}/etc/zem_order ${ZCE_PREFIX}/gui/lighttpd/etc/zem_order
ln -sf ${ZCE_PREFIX}/gui/UserServer ${ZCE_PREFIX}/apache2/htdocs/ZendServer
ln -sf ${ZCE_PREFIX}/gui/html ${ZCE_PREFIX}/gui/lighttpd/htdocs/ZendServer
ln -sf ${ZCE_PREFIX}/apache2/bin/apachectl ${ZCE_PREFIX}/bin/apachectl
ln -sf ${ZCE_PREFIX}/apache2/logs/error_log ${ZCE_PREFIX}/var/log/error.log
ln -sf ${ZCE_PREFIX}/apache2/logs/access_log ${ZCE_PREFIX}/var/log/access.log
# in the event ld scandir is available
if [ -d /etc/ld.so.conf.d ];then
	echo "/usr/local/zend/lib" > /etc/ld.so.conf.d/zend_server.conf
	if which ldconfig > /dev/null 2>&1;then
		ldconfig
	fi
fi
${ZCE_PREFIX}/bin/create_cert.sh
${ZCE_PREFIX}/bin/zendctl.sh start
$ECHO_CMD "${OK_COLOR}========================== INSTALLATION SUMMARY ===================================================\n${T_RESET}"
$ECHO_CMD "     $PRODUCT_NAME was installed to ${ZCE_PREFIX}"
$ECHO_CMD "     The End User License Agreement [EULA] can be viewed under $ZCE_PREFIX/doc/EULA.txt"
$ECHO_CMD "     See the README in $ZCE_PREFIX/doc/README  more information\n"
$ECHO_CMD "     To change the GUI password run $ZCE_PREFIX/bin/gui_passwd.sh"
$ECHO_CMD "     Apache is up and running on port 10088!"
$ECHO_CMD "     To control $PRODUCT_NAME, please use ${ZCE_PREFIX}/bin/zendctl.sh"
$ECHO_CMD "     To enable the Java bridge, please run ${ZCE_PREFIX}/bin/setup_jb.sh"
$ECHO_CMD "     Web interface is accessible from https://localhost:10082/ZendServer\n"
$ECHO_CMD "${OK_COLOR}=============================== ENJOY $PRODUCT_NAME ===============================================${T_RESET}"

