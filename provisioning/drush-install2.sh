#! /usr/bin/bash
#
# Drupal initial config with drush

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
#export readonly PROVISIONING_SCRIPTS="/vagrant/provisioning/"
# Location of files to be copied to this server
#export readonly PROVISIONING_FILES="${PROVISIONING_SCRIPTS}/files/${HOSTNAME}"

db_root_password=root
db_username=thomas
db_userpass=thomas
db_name=drupal
site_naam=groep02_testsite
site_mail=test@test.com
profile=standard
drush_bin=/home/vagrant/.config/composer/vendor/drush/drush/drush

#------------------------------------------------------------------------------
# "Imports"
#------------------------------------------------------------------------------

# Utility functions
#source ${PROVISIONING_SCRIPTS}/util.sh
# Actions/settings common to all servers
#source ${PROVISIONING_SCRIPTS}/common.sh

#------------------------------------------------------------------------------
# Script
#------------------------------------------------------------------------------

drush si $profile -y \
  --db-url=mysql://$db_username:$db_userpass@localhost/$db_name \
  --site-name=$site_naam \
  --site-mail=$site_mail \
  --account-mail=$site_mail \
  --account-name=$db_username \
  --account-pass=$db_userpass >> /dev/null 2>&1

  drush si standard -y --db-url=mysql://thomas:thomas@localhost/drupal --site-name=groep02_testsite --site-mail=test@test.com --account-mail=test@test.com --account-name=thomas --account-pass=groep02hogent

sudo drush si standard --db-url=mysql://thomas:thomas@127.0.0.1/drupal --db-su=root --db-su-pw=root --site-name="groep 02 testsite" 

drush si standard --db-url=mysql://root:root@localhost/drupal7 --db-su=root --db-su-pw=root --site-name="Drupal on Vagrant"



