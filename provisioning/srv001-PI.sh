#! /bin/bash
#
# Provisioning script for srv001-PI

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
export readonly PROVISIONING_SCRIPTS="/boot/provisioning"
# Location of files to be copied to this server
#export readonly PROVISIONING_FILES="${PROVISIONING_SCRIPTS}/files/${HOSTNAME}"

# wijzig om andere webapp module te gebruiken
# opties: wordpress, drupal
app_module=drupal
# wijzigen volgende vars is optioneel/naar voorkeur
db_root_password=root 
db_username=thomas
db_userpass=thomas
db_name=$app_module
site_naam=PI_testsite
site_mail=test@test.com

# niet wijzigen
cloud=1
profile=standard

#------------------------------------------------------------------------------
# Provision server
#------------------------------------------------------------------------------

echo "Starting server specific provisioning tasks on ${HOSTNAME}"

# prep (uitvoeren als root voor gemak + repo's syncen):
#sudo su
apt-get update

# nodige packages installeren (lamp stack):
apt-get install apache2 php7.0 libapache2-mod-php7.0 openssl -y
apt-get install mysql-server php7.0-mysql -y

systemctl restart apache2

# non interactieve variant van mysql_secure_installation
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

echo "Completed server specific provisioning tasks on ${HOSTNAME}"
