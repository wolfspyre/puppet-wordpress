# == Class: wordpress::dependent::requirements
#  This class installs the required packages for a dependent wordpress setup
#
class wordpress::dependent::requirements {
  #localize variables
  $ensure        = $wordpress::package_ensure
  $config_mode   = $wordpress::dependent::config_mode
  #$mysql_version = $wordpress::mysql_version
  #repo module comes before -> Class['wordpress::dependent::requirements']
  # end of localized variables
  case $::osfamily {
    RedHat: {
      case $::lsbmajdistrelease {
        5: {
          #wordpress requires php53, not php5.
          $remove_php = true
        }
        default: {
          #only need to remove php* packages on rh5.
          $remove_php = false
        }
      }
    }
    default: {
      #only applies to rh OSes
      $remove_php = false
    }
  }
  if $remove_php {
    package { ['php','php-common']:
      ensure => 'absent',
      before => [Class['mysql::php'],Apache::Mod['php5']]
    }
  }
  case $config_mode {
  # we support two modes here:
  # [*dependent*] which requires the puppetlabs apache and mysql modules, and
  # [*apponly*] which only requires the puppetlabs apache module
    apponly: {
      include apache, apache::params, apache::mod::php
      #include mysql::params, mysql::php
      #include profile::mysql_factory
      $apache_pkg = $apache::params::apache_name
      #gonna need a way to pull-in php-mysql packages here in a not dumb way.
    }
    dependent: {
      include apache, apache::params, apache::mod::php
      include mysql, mysql::params, mysql::server, mysql::php
      #include profile::mysql_factory
      $apache_pkg = $apache::params::apache_name
      #Service['httpd',$mysql::server::service_name ]
      # Not sure why I needed these.
      #Package[$apache_pkg] -> Apache::Vhost['default']
      #Package[$apache_pkg] -> Apache::Vhost['default-ssl']
    }
    default: {
      fail "unsupported config_mode value: \"${config_mode}\" for $::{fqdn}. Supported values are dependent, standalone, or apponly."
    }
  }#end config_mode case
}#end class
