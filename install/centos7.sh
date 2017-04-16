#!/bin/sh
########################################################################
# Developed by Hugo Maza M.
# hugo.maza@gmail.com
# 
# miquiloni is a Web UI for LXC Servers management
# 
# Writen in free style Perl-CGI + Apache + MySQL + Javascript + CSS
# 
# <one line to give the program's name and a brief idea of what it does.>
# Copyright (C) <year>  <name of author>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################

source ./keys_auto.conf

chown apache:apache /usr/share/httpd

service NetworkManager stop

chkconfig NetworkManager off

service firewalld stop

chkconfig firewalld off

service httpd start

service mysqld start

chkconfig httpd on

chkconfig mysqld on

perl -pi -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

setenforce 0

perl -pi -e 's/Listen 80/Listen 80\nListen 443\n\nTimeout 1200/' /etc/httpd/conf/httpd.conf

mkdir /var/www/miquiloni

mkdir /var/www/miquiloni/html

mkdir /var/www/miquiloni/keys

mkdir /var/www/miquiloni/certs

mkdir /var/www/miquiloni/logs

perl -pi -e "s/SERVER_NAME/${COMMON_NAME}/" miquiloni_apache.conf

cat ./miquiloni_apache.conf > /etc/httpd/conf.d/miquiloni.conf

mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.bk

cp -r ../html/* /var/www/miquiloni/html/

mysqlPasswdAdmin=`./generateEncKey.pl 12`
perl -pi -e "s/DBPASSWD/DBPASSWD \= ${mysqlPasswdAdmin}/g" /var/www/miquiloni/html/miquiloni.conf
perl -pi -e "s/MYSQL_PASSWD/${mysqlPasswdAdmin}/g" miquiloni.sql

encKey=`./generateEncKey.pl`;
echo "${encKey}" > /var/www/miquiloni/certs/miquilonikey.enc

encPasswd=`./cryptPasswdAdmin.pl admin`
perl -pi -e "s/ADMIN_PASSWD/${encPasswd}/" miquiloni.sql

cd /var/www/miquiloni/certs

openssl req -new -x509 -nodes -days 3650 -newkey rsa:2048 -keyout miquiloni-private.key -out miquiloni-cert.crt -subj "/C=${COUNTRY}/ST=${CITY}/L=Region/O=${REGION}/OU=${ORGANIZATION}/CN=${COMMON_NAME}"

chown -R apache:apache /var/www/miquiloni

service httpd restart

/usr/bin/find /var/www/miquiloni/html -name *.cgi -exec chmod 755 {} \;


