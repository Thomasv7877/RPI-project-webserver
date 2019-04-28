#! /bin/bash
#
# Specifieke taken voor Drupal

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