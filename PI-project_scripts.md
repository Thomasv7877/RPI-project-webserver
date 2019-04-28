## svr001-PI.sh

Dit zet het lamp platform op, de andere scripts zullen de respectievelijke webapplicatie installeren.

```bash
..
#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

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
```

## wordpress.sh

```bash
#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

wp_dir="/var/www/html/wordpress/wp-config.php"
wp="sudo -u www-data /usr/local/bin/wp"
#pub_ip=$(dig +short myip.opendns.com @resolver1.opendns.com) # alt, bind-utils nodig
#pub_ip="192.168.1.3"
pub_ip=$(hostname -I | cut -d" " -f1)

#------------------------------------------------------------------------------
# Script
#------------------------------------------------------------------------------

# var pub_ip wijzigen indien nodig, later gebruikt bij wp site-install
if [ $cloud -eq 0 ] ; then
  pub_ip=$(curl icanhazip.com)
fi

# install wp-cli:
cd /tmp
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# wordpress dir aanmaken:
mkdir /var/www/html/wordpress
cd /var/www/html/wordpress
# om wordpress dir toegakelijk te maken door apache ('www-data' of 'apache' afhankelijk van distro):
chown -R www-data:www-data /var/www/html/
# default geen selinux op raspbian
#chcon -R -t httpd_sys_content_rw_t /var/www/html/
# wp-cli - download wordpress:
$wp core download
# wp-cli - maak een config file aan:
$wp config create --dbname=${db_name} --dbuser=${db_username} --dbpass=${db_userpass}
# wp-cli - doe de initieele site install
$wp core install --url="${pub_ip}/${db_name}" --title=${site_naam} --admin_user=${db_username} --admin_password=${db_userpass} --admin_email=${site_mail}
```

## drupal.sh

```bash
..
#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

drupal_dir=/var/www/html/drupal
#drush_bin=/root/.config/composer/vendor/bin/drush
drush_bin=/root/.composer/vendor/bin/drush
# alts:
#drush_bin=/home/vagrant/.config/composer/vendor/drush/drush/drush
#drush_bin=/root/.config/composer/vendor/drush/drush/drush

#------------------------------------------------------------------------------
# Script
#------------------------------------------------------------------------------

# basic drupal download en install:
cd /tmp
wget -c https://www.drupal.org/download-latest/tar.gz
tar -zxf tar.gz
mv drupal-* $drupal_dir
cd ${drupal_dir}/sites/default/
cp default.settings.php settings.php

# prerequisite(s) drupal, om oa clean urls te kunnen gebruiken
sed -i 's:AllowOverride None:AllowOverride All:' /etc/apache2/apache2.conf
a2enmod rewrite # alleen nodig icm debian

# composer is nodig om recentste drush versie (9.x) te kunnen installeren
# nodig omdat drush uit de centos/debian repos niet compatibel is met de laatste drupal versie
apt-get install -y composer php-xml php-gd
# install drush
composer global require drush/drush
# initieele site install/config uitvoeren
cd $drupal_dir
$drush_bin si $profile -y --db-url=mysql://$db_username:$db_userpass@localhost/$db_name --site-name=$site_naam --account-pass=$db_userpass --account-name=$db_username

# drupal dir bruikbaar maken door apache:
chown -R www-data:www-data $drupal_dir
# nodige selinux wijziging, hier niet nodig omdat Raspbian op de PI standaard geen selinux heeft
#chcon -R -t httpd_sys_content_rw_t $drupal_dir
# om config wijzigingen door te voeren
systemctl restart apache2
```