# == Class: wordpress
#
# Full description of class wordpress here.
#
# === Parameters
#
#[*app_archive*]:
#  This should be the filename of the zip file containing the wordpress version
#
#[*config_mode*]:
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
#[*app_dir*]: 'wordpress'
#  The child directory beneath app_parent to install the vhost into
#  in standalone mode
#
#[*app_hash*]:
#  This is the meat of the vhost/db config. Allows for the instantiation of
#  multiple wp sites on one box. Elements in hash:
#    port              - TCP port apache vhost should listen on
#    docroot           - The document root for the vhost. Must end in a trailing /
#    db_name           - The name of the db wordpress will use
#    db_user           - The mysql username wordpress will access the db via
#    db_password       - The mysql password wordpress will access the db with
#    db_host           - The host the db lives on.
#      *This module will only create a db if this is localhost|127.0.0.1*
#    wp_install_parent - The parent dir that wordpress will be extracted into.
#       *must end in a trailing /*
#       *wordpress will live in wp_install_parent/wordpress/*
#    wp_owner          - User account that owns wp. Defaults to apache's user.
#    wp_group          - The group that owns wp. Defaults to apache's group.
#    create_user       - true/false string
#    create_group      - true/false string
#    create_vhost      - true/false string
#    vhost_name        - the fqdn the vhost should respond to
#    serveraliases     - aliases the vhost should respond to
#
#
#[*app_parent*]:
#  This directory is the parent dir that app_dir is a subdirectory of
#
#[*mysql_version*]:
#  This is only relevant for standalong version to get package names right in case of non-standard versions of mysql
#
#[*package_ensure*]:
#  ensure value for standalone packages. supported values are present or latest.
# === Variables
#
# Hiera varibles example.
#
########################################################################
#STANDALONE
########################################################################
#wordpress::app_archive: 'wordpress-3.6.1.zip'
#wordpress::app_dir: 'wordpress'
#wordpress::app_hash:
#  wordpressvhost: {
#    port:              '80',
#    docroot:           '/var/www/wordpress/wordpress/',
#    db_name:           'wordpressdb',
#    db_user:           'wordpressdbuser',
#    db_password:       'wpDBUpa55word',
#    db_host:           'localhost',
#    wp_install_parent: '/var/www/wordpress/',
#    wp_owner:          'wordpress',
#    wp_group:          'wordpress',
#    vhost_name:        "%{::network_primary_ip}",
#    serveraliases:     "%{::hostname}",
#    create_user:       true,
#    create_group:      true,
#    create_vhost:      true
#  }
#wordpress::app_parent: '/opt/'
#wordpress::config_mode: 'standalone'
#wordpress::mysql_version: '5.5'
#wordpress::package_ensure: 'present'
########################################################################
#DEPENDENT
########################################################################
#wordpress::app_archive: 'wordpress-3.6.1.zip'
#wordpress::app_dir: 'wordpress'
#wordpress::app_hash:
#  wordpressvhost: {
#    port:              '80',
#    docroot:           '/var/www/wordpress/wordpress/',
#    db_name:           'wordpressdb',
#    db_user:           'wordpressdbuser',
#    db_password:       'wpDBUpa55word',
#    db_host:           'localhost',
#    wp_install_parent: '/var/www/wordpress',
#    wp_owner:          'wordpress',
#    wp_group:          'wordpress',
#    vhost_name:        "%{::network_primary_ip}",
#    serveraliases:     "%{::hostname}",
#    create_user:       true,
#    create_group:      true,
#    create_vhost:      true
#  }
#wordpress::app_parent: '/opt/'
#wordpress::config_mode: 'dependent'
#wordpress::mysql_version: '5.5'
#wordpress::package_ensure: 'present'
#
# NOTE: if trying to use this module on rh5 in dependent/apponly mode
#   you MUST use php53. This may require adjusting the php parameters
#   of both mysql::php, apache,  and apache::mod
#
# === Dependencies
#
# puppet-network
#
# dependent mode dependencies:
# puppetlabs-mysql
# puppetlabs-apache
# concat
#
# === Authors
#
# Wolf Noble <wolf@wolfspyre.com>
#
# === Copyright
#
# Copyright 2011
#
class wordpress(
  $app_archive        = 'wordpress-3.9.1.zip',
  $app_dir            = 'wordpress',
  $app_hash           = {'wordpressvhost' => {
      port              => '80',
      docroot           => '/var/www/wordpress/wordpress/',
      wp_install_parent => '/var/www/wordpress/',
      db_name           => 'wordpressdb',
      db_user           => 'wordpressdbuser',
      db_password       => undef,
      db_host           => 'localhost',
      wp_owner          => 'wordpress',
      wp_group          => 'wordpress',
      create_user       => true,
      create_group      => true,
      create_vhost      => true,
      vhost_name        => $::network_primary_ip,
      serveraliases     => "${::hostname},${::fqdn},wordpress.${::domain}"}},
  $app_parent         = undef,
  $config_mode        = 'noop',
  $enable_scponly     = true,
  $manage_scponly_pkg = true,
  $mysql_version      = '5.5',
  $package_ensure     = 'present'
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
    'noop': {
      #do-nothing default value to permit unit testing of sub-modes.
    }
    default: {
      fail "unsupported config_mode value: \"${config_mode}\" for ${::fqdn}. Supported values are dependent, standalone, or apponly."
    }
  }
  $supportedval=[present,latest]

  validate_bool($enable_scponly)
  validate_bool($manage_scponly_pkg)

  validate_re($package_ensure, $supportedval)
  if $manage_scponly_pkg {
    include wordpress::scponly
  }

}#end of wordpress class
