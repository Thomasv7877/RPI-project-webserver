#! /usr/bin/bash
#
# Provisioning script for srv001

#------------------------------------------------------------------------------
# Bash settings
#------------------------------------------------------------------------------

# abort on nonzero exitstatus
set -o errexit
# abort on unbound variable
set -o nounset
# don't mask errors in piped commands
set -o pipefail

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

# Location of provisioning scripts and files
export readonly PROVISIONING_SCRIPTS="/vagrant/provisioning/"
# Location of files to be copied to this server
export readonly PROVISIONING_FILES="${PROVISIONING_SCRIPTS}/files/${HOSTNAME}"

# wijzig om andere webapp module te gebruiken
# opties: wordpress, drupal
app_module=drupal
# wijzigen volgende vars is optioneel/naar voorkeur
db_root_password=root 
db_username=thomas
db_userpass=thomas
db_name=$app_module
site_naam=groep02_testsite
site_mail=test@test.com

# niet wijzigen
cloud=1
profile=standard

#------------------------------------------------------------------------------
# "Imports"
#------------------------------------------------------------------------------

# Utility functions
source ${PROVISIONING_SCRIPTS}/util.sh
# Actions/settings common to all servers
source ${PROVISIONING_SCRIPTS}/common.sh

#------------------------------------------------------------------------------
# Provision server
#------------------------------------------------------------------------------

info "Starting server specific provisioning tasks on ${HOSTNAME}"

# TODO: insert code here, e.g. install Apache, add users (see the provided
# functions in utils.sh), etc.

## nodige packages installeren
# repo's voor php 7 toevoegen, anders geen drupal 8
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
#yum -y install epel-release
# oude manier voor default php 5
# yum install -y httpd php php-mysqlnd mod_ssl mariadb-server
# veel extra php packages nodig om drupal requirements te laten slagen
yum install -y httpd php70w php70w-opcache php70w-mbstring php70w-gd php70w-xml php70w-pear php70w-fpm php70w-mysql php70w-pdo mod_ssl mariadb-server

# firewall, apache en mariadb services enablen en starten
systemctl start firewalld
systemctl enable firewalld
systemctl start httpd
systemctl enable httpd
systemctl start mariadb
systemctl enable mariadb

# apache door firewall laten
firewall-cmd --add-service=http
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https
firewall-cmd --add-service=https --permanent
firewall-cmd --reload

## non interactieve variant van mysql_secure_installation
mysql --user=root <<_EOF_
UPDATE mysql.user SET Password=PASSWORD('${db_root_password}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_

# php test pagina maken
echo "<?php  phpinfo(); ?>" > /var/www/html/info.php

# webapp db maken
mysql --user=root --password=${db_root_password} <<_EOF_
create database ${db_name};
create user ${db_username}@localhost identified by '${db_userpass}';
grant all on ${db_name}.* to ${db_username}@localhost;
flush privileges;
_EOF_

# deeltaken om gewenste webapplicatie te installeren oproepen
source ${PROVISIONING_SCRIPTS}/apps/${db_name}.sh

info "Completed server specific provisioning tasks on ${HOSTNAME}"
