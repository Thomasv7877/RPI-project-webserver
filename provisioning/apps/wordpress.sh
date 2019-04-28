#! /bin/bash
#
# Specifieke taken voor Wordpress

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

### oude installatiemethode, zonder wp-cli:
# wget http://wordpress.org/latest.tar.gz
# tar -xzf latest.tar.gz
# mv wordpress /var/www/html/
# cd /var/www/html/wordpress
# cp wp-config-sample.php wp-config.php
# chown -R apache:apache /var/www/html/wordpress/
# chcon -R -t httpd_sys_content_rw_t /var/www/html/wordpress/
# # db gegevens in settings bestand zetten
# sed -i "s:database_name_here:${db_name}:" $wp_dir
# sed -i "s:username_here:${db_username}:" $wp_dir
# sed -i "s:password_here:${db_userpass}:" $wp_dir
# systemctl restart httpd
###