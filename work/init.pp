# == Class: wordpress
#
# Full description of class wordpress here.
#
# === Parameters
#
#[*wordpress_app_archive*]:
#  This should be the filename of the zip file containing the wordpress version
#
#[*wordpress_config_mode*]:
# This should be one value of standalone, dependent or apponly
#   standalone:
#     assumes it's an island, installs everything minially and configures one
#     instance of wordpress.
#   dependent:
#     assumes everything is on one node. depends on puppetlabs/apache and
#     puppetlabs/mysql.
#   apponly:
#     only creates a vhost and deploys the app there. depends on
#     puppetlabs/apache
#
#[*wordpress_app_dir*]: 'wordpress'
#  The child directory beneath wordpress_app_parent to install the vhost into
#  in standalone mode
#
#[*wordpress_app_hash*]:
#  This is the meat of the vhost/db config. Allows for the instantiation of
#  multiple wp sites on one box. Elements in hash:
#    port              - TCP port apache vhost should listen on
#    docroot           - The document root for the vhost
#    db_name           - The name of the db wordpress will use
#    db_user           - The mysql username wordpress will access the db via
#    db_password       - The mysql password wordpress will access the db with
#    db_host           - The host the db lives on.
#      *This module will only create a db if this is localhost|127.0.0.1*
#    wp_install_parent - The parent dir that wordpress will be extracted into.
#       *wordpress will live in wp_install_parent/wordpress/*
#    wp_owner          - User account that owns wp. Defaults to apache's user.
#    wp_owner_ssh_key  - The public ssh key to add for the user. 
#       *should not be added for apache*
#    wp_owner_ssh_name - The public ssh key name
#    wp_owner_ssh_opts - The public ssh key options Key options, see sshd(8) for possible values. Multiple values should be specified as an array.
#    wp_owner_ssh_type - The public ssh key type
#    wp_group          - The group that owns wp. Defaults to apache's group.
#    create_user       - true/false string
#    create_group      - true/false string
#    create_vhost      - true/false string
#    vhost_name        - the fqdn the vhost should respond to
#    serveraliases     - aliases the vhost should respond to
#
#
#[*wordpress_app_parent*]:
#  This directory is the parent dir that wordpress_app_dir is a subdirectory of
#
#[*wordpress_mysql_version*]:
#  This is only relevant for standalong version to get package names right in case of non-standard versions of mysql
#
#[*wordpress_package_ensure*]:
#  ensure value for standalone packages. supported values are present or latest.
# === Variables
#
# Hiera varibles example.
#
#wordpress_app_archive: 'wordpress-3.4.1.zip'
#wordpress_app_dir: 'wordpress'
#wordpress_app_hash:
#  wordpressvhost: {
#    port:              '80',
#    docroot:           '/var/www/wordpress/wordpress',
#    db_name:           'wordpressdb',
#    db_user:           'wordpressdbuser',
#    db_password:       'wpDBUpa55word',
#    db_host:           'localhost',
#    wp_install_parent: '/var/www/wordpress',
#    wp_owner:          'wordpress',
#    wp_group:          'wordpress',
#    wp_owner_ssh_key:  '',
#    wp_owner_ssh_name: '',
#    wp_owner_ssh_opts: '',
#    wp_owner_ssh_type: '',
#    vhost_name:        %{fqdn},
#    serveraliases:     %{hostname},
#    create_user:       'true',
#    create_group:      'true'
#    create_vhost:      'true'
#  }
#wordpress_app_parent: '/opt/'
#wordpress_config_mode: 'dependent'
#wordpress_mysql_version: '5.5'
#wordpress_package_ensure: 'present'
#
# NOTE: if trying to use this module on rh5 in dependent/apponly mode
#   you MUST use php53. This may require adjusting the php parameters
#   of both mysql::php, apache,  and apache::mod
#
# === Authors
#
# Wolf Noble <wolf@wolfspyre.com>
#
# === Copyright
#
#
class wordpress(
  $wordpress_app_archive    = hiera('wordpress_app_archive', 'wordpress-3.4.1.zip' ),
  $wordpress_app_dir        = hiera('wordpress_app_dir', 'wordpress'),
  $wordpress_app_hash       = hiera('wordpress_app_hash', {
    wordpressvhost => {
      port              => '80',
      docroot           => '/var/www/wordpress/wordpress',
      wp_install_parent => '/var/www/wordpress',
      db_name           => 'wordpressdb',
      db_user           => 'wordpressdbuser',
      db_password       => undef,
      db_host           => 'localhost',
      wp_owner          => 'wordpress',
      wp_owner_ssh_key  => '',
      wp_owner_ssh_name => '',
      wp_owner_ssh_opts => '',
      wp_owner_ssh_type => '',
      wp_group          => 'wordpress',
      create_user       => 'true',
      create_group      => 'true',
      create_vhost      => 'true',
      vhost_name        => $::ipaddress,
      serveraliases     => "$::{hostname},$::{fqdn},wordpress.$::{domain}"
    }
  }),
  $wordpress_app_parent     = hiera('wordpress_app_parent', '/opt/'),
  $wordpress_config_mode    = hiera('wordpress_config_mode','dependent'),
  $wordpress_mysql_version  = hiera('wordpress_mysql_version', '5.5'),
  $wordpress_package_ensure = hiera('wordpress_package_ensure', 'present')
  ) {
    #take advantage of the Anchor pattern
  anchor{'wordpress::begin':}
  -> anchor {'wordpress::package::begin':}
  -> anchor {'wordpress::package::end':}
  -> anchor {'wordpress::config::begin':}
  -> anchor {'wordpress::config::end':}
  -> anchor {'wordpress::service::begin':}
  -> anchor {'wordpress::service::end':}
  -> anchor {'wordpress::end':}
  #turn parameters into more sanely named variables
  $config_mode   = $wordpress_config_mode
  $app_archive   = $wordpress_app_archive
  $app_dir       = $wordpress_app_dir
  $app_hash      = $wordpress_app_hash
  $app_parent    = $wordpress_app_parent
  $mysql_version = $wordpress_mysql_version

  case $config_mode {
    'dependent': {
      include wordpress::dependent
      #fail 'dependent not implemented yet'
    }
    'standalone': {
      include wordpress::standalone
    }
    'apponly': {
      include wordpress::dependent
      #fail 'apponly not implemented yet'
    }
    default: {
      fail "unsupported config_mode value: \"${config_mode}\" for ${fqdn}. Supported values are dependent, standalone, or apponly."
    }
  }
  case $wordpress_package_ensure {
    /[pP][rR][eE][sS][eE][nN][tT]/: {
      $package_ensure = 'present'
    }
    /[lL][aA][tT][eE][sS][tT]/: {
      $package_ensure = 'latest'
    }
    default: {
      fail "unsupported package_ensure value: \"${wordpress_package_ensure}\" for ${fqdn}. Supported values are 'present' or 'latest'."
    }
  }

}#end of wordpress class
