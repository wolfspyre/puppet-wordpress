# == Class: wordpress::dependent::requirements
#  This class installs the required packages for a dependent wordpress setup
#
class wordpress::dependent::requirements {
  #localize variables
  $ensure        = $wordpress::requirements_ensure
  $config_mode   = $wordpress::config_mode
  $mysql_version = $wordpress::mysql_version
  #repo module ends here -> Class['wordpress::dependent::requirements']
  # end of localized variables
  case $config_mode {
  # we support two modes here:
  # [*dependent*] which requires the puppetlabs apache and mysql modules, and
  # [*apponly*] which only requires the puppetlabs apache module
    apponly: {
      include apache, apache::params, apache::mod::php, mysql::params, mysql::php
      $apache_pkg = $apache::params::apache_name
      #gonna need a way to pull-in php-mysql packages here in a not dumb way.
      Service['httpd'] -> Class['wordpress::dependent::config']
    }
    dependent: {
      include apache, apache::params, apache::mod::php, mysql, mysql::params, mysql::server, mysql::php
      $apache_pkg = $apache::params::apache_name
      $php_mysql_pkg = $mysql::params::php_package_name
      Service['httpd',$mysql::server::service_name ] -> Class['wordpress::dependent::config']
    }
    default: {
      fail "unsupported config_mode value: \"${config_mode}\" for $::{fqdn}. Supported values are dependent, standalone, or apponly."
    }
  }#end config_mode case
}#end class

