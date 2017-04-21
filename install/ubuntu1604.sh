#!/bin/bash
########################################################################
# Miquiloni is a Web UI for LXC Servers management
# Copyright (C) 2017  Hugo Maza M.
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

apt install -y apache2 mysql-server sshpass libnet-openssh-perl libdbi-perl libdbd-mysql-perl

/usr/bin/perl -pi -e 's/Timeout 300/Timeout 1200/' /etc/apache2/apache2.conf

a2enmod ssl

a2enmod cgi

mkdir /var/www/miquiloni

mkdir /var/www/miquiloni/html

mkdir /var/www/miquiloni/keys

mkdir /var/www/miquiloni/certs

mkdir /var/www/miquiloni/logs

/usr/bin/perl -pi -e "s/SERVER_NAME/${COMMON_NAME}/" miquiloni_apache.conf

cat ./miquiloni_apache.conf > /etc/apache2/sites-available/miquiloni.conf

mv /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bk

cp -r ../html/* /var/www/miquiloni/html/

chown www-data:www-data /var/www

mysqlPasswdAdmin=`./generateEncKey.pl 12`
/usr/bin/perl -pi -e "s/DBPASSWD/DBPASSWD \= ${mysqlPasswdAdmin}/g" /var/www/miquiloni/html/miquiloni.conf
/usr/bin/perl -pi -e "s/MYSQL_PASSWD/${mysqlPasswdAdmin}/g" miquiloni.sql

encKey=`./generateEncKey.pl`;
echo "${encKey}" > /var/www/miquiloni/certs/miquilonikey.enc

encPasswd=`./cryptPasswdAdmin.pl admin`
/usr/bin/perl -pi -e "s/ADMIN_PASSWD/${encPasswd}/" miquiloni.sql

cd /var/www/miquiloni/certs

openssl req -new -x509 -nodes -days 3650 -newkey rsa:2048 -keyout miquiloni-private.key -out miquiloni-cert.crt -subj "/C=${COUNTRY}/ST=${CITY}/L=Region/O=${REGION}/OU=${ORGANIZATION}/CN=${COMMON_NAME}"

chown -R www-data:www-data /var/www/miquiloni

service apache2 restart

cd /etc/apache2/sites-available

a2ensite miquiloni.conf

service apache2 restart

/usr/bin/find /var/www/miquiloni/html -name *.cgi -exec chmod 755 {} \;


